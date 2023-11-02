#!/bin/bash
#*************************
# Create a Cluster with Karpenter
#************************* 
echo "${GREEN}=========================="
echo "${GREEN}Installing Cluster"
echo "${GREEN}=========================="
source ./deployment/environmentVariables.sh

if [ -z $CLUSTER_NAME ] || [ -z $KARPENTER_VERSION ] || [ -z $AWS_REGION ] || [ -z $ACCOUNT_ID ] || [ -z $TEMPOUT ];then
echo "${RED}Update values & Run environmentVariables.sh file"
exit 1;
else 
echo "${GREEN}**Start cluster provisioning**"

CHECK_CLUSTER=$(aws eks list-clusters | jq -r ".clusters" | grep $CLUSTER_NAME || true)
if [ ! -z $CHECK_CLUSTER ];then
echo "${BLUE}Cluster Exists"
else
echo "${YELLOW}Cluster does not exists"
echo "${GREEN} !!Create a eks cluster !!"

eksctl create cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --version ${K8sversion} --tags karpenter.sh/discovery=${CLUSTER_NAME}
#aws eks describe-cluster --region ${AWS_REGION} --name ${CLUSTER_NAME} --query "cluster.status"

fi
# Delete eks cluster
#eksctl delete cluster --name eks-keda-scale --region  us-west-1#
echo "${GREEN}==========================" 
echo "${GREEN}Cluster Completed"
echo "${GREEN}=========================="
fi
