#!/bin/bash
#*************************
# Deploy Karpenter
#*************************
## SWITCH CLUSTER CONTEXT
echo "${GREEN}=========================="
echo "${GREEN}Installing karpenter"
echo "${GREEN}=========================="

source ./deployment/environmentVariables.sh

echo "${RED}Casesenstive ${BLUE} Press Y = Proceed \n or \n N = Cancel (change context 'kubectl config use-context {context name you can check using kubectl config view}' and run script)"
read user_input
#kubectl config use-context akaasif-Isengard@${CLUSTER_NAME}.${AWS_REGION}.eksctl.io
#kubectl config current-context
#kubectl config use-context akaasif-Isengard@eks-karpenter-scale.us-west-1.eksctl.io

Entry='Y'
if [[ "$user_input" == *"$Entry"* ]]; then

if [ -z $CLUSTER_NAME ] || [ -z $KARPENTER_VERSION ] || [ -z $AWS_REGION ] || [ -z $ACCOUNT_ID ] || [ -z $TEMPOUT ];then
echo "${RED}Update values & Run environmentVariables.sh file"
exit 1;
else 
echo "${GREEN}**Installing karpenter**"
# If you have login with docker in shell  execute below first
docker logout public.ecr.aws

#Create the KarpenterNode IAM Role
echo "${GREEN}Create the KarpenterNode IAM Role"

curl -fsSL https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}" \
  --region ${AWS_REGION}


#grant access to instances using the profile to connect to the cluster. This command adds the Karpenter node role to your aws-auth configmap, 
#allowing nodes with this role to connect to the cluster.

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster  ${CLUSTER_NAME} \
  --arn "arn:aws:iam::${ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes 

echo "Verify auth Map"
kubectl describe configmap -n kube-system aws-auth

# Create KarpenterController IAM Role
echo "Create KarpenterController IAM Role"

eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

#Karpenter requires permissions like launching instances. This will create an AWS IAM Role, Kubernetes service account, 
#and associate them using IAM Roles for Service Accounts (IRSA)
echo "Map AWS IAM Role  Kubernetes service account"

eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "Karpenter-${CLUSTER_NAME}" \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/Karpenter-${CLUSTER_NAME}"

#Create the EC2 Spot Linked Role
echo "Create the EC2 Spot Linked Role"
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com 2> /dev/null || echo 'Already exist'

#Helm Install Karpenter
echo "Helm Install Karpenter"
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --namespace karpenter --create-namespace \
  --version ${KARPENTER_VERSION} \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.aws.clusterName=${CLUSTER_NAME} \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --set settings.aws.interruptionQueueName=${CLUSTER_NAME} \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

#deploy Provisioner & AWSNodeTemplate 
echo "Providers & AWSNodeTemplate "
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  labels:
    intent: apps
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: karpenter.k8s.aws/instance-size
      operator: NotIn
      values: [nano, micro, small, medium, large]
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  ttlSecondsAfterEmpty: 30
  ttlSecondsUntilExpired: 2592000
  providerRef:
    name: default
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    alpha.eksctl.io/cluster-name: ${CLUSTER_NAME}
  securityGroupSelector:
    alpha.eksctl.io/cluster-name: ${CLUSTER_NAME}
  tags:
    KarpenerProvisionerName: "default"
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF
echo "${GREEN}=========================="
echo "${GREEN}Karpenter Completed"
echo "${GREEN}=========================="
fi

fi