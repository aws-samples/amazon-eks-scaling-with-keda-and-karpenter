#!/bin/bash
#*************************
# Deploy KEDA
#*************************
echo "${GREEN}=========================="
echo "${GREEN}Deploy KEDA"
echo "${GREEN}=========================="
source ./deployment/environmentVariables.sh

echo "${RED} Keda will be deployed on cluster $(kubectl config current-context) \n ${RED}Casesenstive ${BLUE}Press Y = Proceed or N = Cancel (change context and run script)"
read user_input

Entry='Y'
if [[ "$user_input" == *"$Entry"* ]]; then
OIDC_PROVIDER=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

echo "${CYAN}This deployment will target AWS SQS trigger for keda"

if [ -z $CLUSTER_NAME ] ||  [ -z $AWS_REGION ] || [ -z $IAM_KEDA_SQS_POLICY ] || [ -z $IAM_KEDA_DYNAMO_POLICY ] || [ -z $ACCOUNT_ID ] || [ -z $TEMPOUT ] || [ -z $OIDC_PROVIDER ] || [ -z $IAM_KEDA_ROLE ] || [ -z $SERVICE_ACCOUNT ] || [ -z $NAMESPACE ] || [ -z $SQS_TARGET_NAMESPACE ] || [ -z $SQS_TARGET_DEPLOYMENT ] || [ -z $SQS_QUEUE_URL ];then
echo "${RED}Update values & Run environmentVariables.sh file"
exit 1;
else

echo "====Installing keda====="
#Deploy SQS access policy
echo "${CYAN}Deploy SQS access policy"
SQS_POLICY=$(aws iam create-policy --policy-name ${IAM_KEDA_SQS_POLICY} --policy-document file://deployment/keda/sqsPolicy.json --output text --query Policy.Arn)
echo "${GREEN}ARN : ${SQS_POLICY}"
#Deploy Dynamo access policy
# This is needed in context to our sample application, its not a KEDA requirement 
echo "${CYAN}Deploy Dynamo access policy. !!This is needed in context to our sample application, its not a KEDA requirement!!"
DYNAMO_POLICY=$(aws iam create-policy --policy-name ${IAM_KEDA_DYNAMO_POLICY} --policy-document file://deployment/keda/dynamoPolicy.json  --output text --query Policy.Arn)
echo "${GREEN}ARN : ${DYNAMO_POLICY}"


OIDC_PROVIDER=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
echo "${CYAN}Create a trusted relation in role for STS"
#Create Role Trusted Relation 
cat >./deployment/keda/trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": [
            "system:serviceaccount:keda:keda-operator",
            "system:serviceaccount:${SQS_TARGET_NAMESPACE}:${SERVICE_ACCOUNT}"
          ]
        }
      }
    }
  ]
}
EOF

# Create role for KedaOperator to access SQS for poling and generate STS for operator to connect with AWS resources
echo "${GREEN}Create role for KedaOperator to access SQS for poling and generate STS for operator to connect with AWS resources"

KEDA_ROLE=$(aws iam create-role --role-name ${IAM_KEDA_ROLE}  --assume-role-policy-document file://deployment/keda/trust-relationship.json --description "keda role-description" --output text)
echo "KEDA ROLE : ${KEDA_ROLE}"
echo "Attach SQS polciy to Keda role"
aws iam attach-role-policy --role-name ${IAM_KEDA_ROLE} --policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/${IAM_KEDA_SQS_POLICY}
echo "Attach dynamo polciy to Keda role"
aws iam attach-role-policy --role-name ${IAM_KEDA_ROLE} --policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/${IAM_KEDA_DYNAMO_POLICY}

ATTCH_POLICY_LIST=$(aws iam list-attached-role-policies --role-name ${IAM_KEDA_ROLE} --output text)
echo "${GREEN}ATTCH_POLICY_LIST : ${ATTCH_POLICY_LIST}"
# Add a new  Kubernetes service account and attach keda-role
echo "Create a K8s service account and attach role"
kubectl create namespace keda-test
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SERVICE_ACCOUNT}
  namespace: keda-test
EOF
echo "${CYAN}Map k8s service account to IAM role"
kubectl annotate serviceaccount -n keda-test keda-service-account eks.amazonaws.com/role-arn=arn:aws:iam::${ACCOUNT_ID}:role/${IAM_KEDA_ROLE}



#Deploy KEDA value
echo "=== Deploy KEDA VALUES ==="
./deployment/keda/values.sh
#Install KEDA with helm 
echo "${CYAN}Install Keda using helm" 
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm install keda kedacore/keda --values ./deployment/keda/value.yaml --namespace keda

echo "${CYAN}=== Deploy KEDA Scaleobject ==="
./deployment/keda/keda-scaleobject.sh
kubectl apply -f ./deployment/keda/kedaScaleObject.yaml

# deploy the application to read queue
echo "${CYAN}Deploy application to read SQS"
#kubectl apply -f ./deployment/app/keda-python-app.yaml

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sqs-app
  namespace: keda-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sqs-reader
  template:
    metadata:
      labels:
        app: sqs-reader
    spec:
      serviceAccountName: keda-service-account
      containers:
      - name: sqs-pull-app
        image: khanasif1/sqs-reader:v0.12
        imagePullPolicy: Always
        env:
        - name: SQS_QUEUE_URL
          value: ${SQS_QUEUE_URL}
        - name: DYNAMODB_TABLE
          value: ${DYNAMODB_TABLE}
        - name: AWS_REGION
          value: ${AWS_REGION}
        resources:
          requests:
            memory: "32Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF


# Clean temporary config file created by script, to save from future conflicts
echo "${RED}Deleting files value.yaml, kedaScaleObject.yaml, trust-relationship.json"
rm -f ./deployment/keda/value.yaml
rm -f ./deployment/keda/kedaScaleObject.yaml
rm -f ./deployment/keda/trust-relationship.json

echo "${GREEN}=========================="
echo "${GREEN}KEDA Completed"
echo "${GREEN}=========================="
fi
fi