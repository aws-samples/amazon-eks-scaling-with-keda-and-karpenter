#******************
# Chain Deployment
#******************
source ./deployment/environmentVariables.sh

echo "${BLUE}Please check the details before proceeding \n AWS Account: ${ACCOUNT_ID} \n AWS Region for deployment : ${AWS_REGION} \n 
${RED}Please check the Karpenter version you have selected is available at \n\n  https://karpenter.sh \n\nAlso please check #Experiencing Issues# section before proceeding.  \n
${RED}Casesenstive ${BLUE}Press Y = Proceed or N = Cancel"
echo "${CYAN}Response: "
read user_input
Entry='Y'
if [[ "$user_input" == *"$Entry"* ]]; then
    CLUSTER=1
    CLUSTER_KARPENTER=2
    CLUSTER_KARPENTER_KEDA=3

    echo "${BLUE} Please select the deployment modules : \n 1. Press 1 to deploy only EKS cluster \n 2. Press 2 to deploy EKS cluster with Karpenter \n 3. Press 3 if you want to deploy EKS cluster, Karpenter & KEDA"
    echo "${CYAN}Response: "
    read user_input 
    if [[ "$user_input" == $CLUSTER ]]; then
        echo "Deploy EKS"
        echo "${GREEN} Proceed deployment"
        echo "Cluster!!"
        echo "${YELLOW}print cluster Parameters \n"
        echo $CLUSTER_NAME  "|" $KARPENTER_VERSION  "|" $AWS_REGION "|"  $ACCOUNT_ID "|"  $TEMPOUT
        chmod u+x ./deployment/cluster/createCluster.sh
        ./deployment/cluster/createCluster.sh
        
    elif [[ "$user_input" == $CLUSTER_KARPENTER ]]; then
        echo "Deploy EKS & Karpenter"
        echo "${GREEN} Proceed deployment"
        echo "Cluster!!"
        echo "${YELLOW}print cluster Parameters \n"
        echo $CLUSTER_NAME  "|" $KARPENTER_VERSION  "|" $AWS_REGION "|"  $ACCOUNT_ID "|"  $TEMPOUT
        chmod u+x ./deployment/cluster/createCluster.sh
        ./deployment/cluster/createCluster.sh

        echo "${GREEN}Karpenter!!"
        echo "${YELLOW}print karpenter Parameters \n"
        echo $CLUSTER_NAME "|"  $KARPENTER_VERSION  "|" $AWS_REGION  "|" $ACCOUNT_ID  "|" $TEMPOUT
        chmod u+x ./deployment/karpenter/createkarpenter.sh
        ./deployment/karpenter/createkarpenter.sh

    elif [[ "$user_input" == $CLUSTER_KARPENTER_KEDA ]]; then
        echo "Deploy EKS & Karpenter & KEDA"
        echo "${GREEN} Proceed deployment"
        echo "Cluster!!"
        echo "${YELLOW}print cluster Parameters \n"
        echo $CLUSTER_NAME  "|" $KARPENTER_VERSION  "|" $AWS_REGION "|"  $ACCOUNT_ID "|"  $TEMPOUT
        chmod u+x ./deployment/cluster/createCluster.sh
        ./deployment/cluster/createCluster.sh

        echo "${GREEN}Karpenter!!"
        echo "${YELLOW}print karpenter Parameters \n"
        echo $CLUSTER_NAME "|"  $KARPENTER_VERSION  "|" $AWS_REGION  "|" $ACCOUNT_ID  "|" $TEMPOUT
        chmod u+x ./deployment/karpenter/createkarpenter.sh
        ./deployment/karpenter/createkarpenter.sh

        echo "${GREEN}KEDA!!"
        echo "${YELLOW}print keda Parameters"
        echo $CLUSTER_NAME "||\n"  $AWS_REGION "||\n"  $ACCOUNT_ID  "||\n" $TEMPOUT  "||\n"  $IAM_KEDA_ROLE  "||\n" $IAM_KEDA_SQS_POLICY  "||\n" $SERVICE_ACCOUNT  "||\n" $NAMESPACE  "||\n" $SQS_TARGET_NAMESPACE "||\n"  $SQS_TARGET_DEPLOYMENT "||\n"  $SQS_QUEUE_URL 
        chmod u+x ./deployment/keda/createkeda.sh
        ./deployment/keda/createkeda.sh

        echo "${GREEN}Deploy Demo components DynamoDB and SQS!!"
        chmod u+x ./deployment/services/awsService.sh 
        ./deployment/services/awsService.sh 
       
    fi 
else

    echo "${RED}Cancel deployment"
fi

