#!/bin/bash
echo "Setting environment variables"
#Shared Variables
export AWS_REGION="ap-southeast-2"
export ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT=$(mktemp) 
export DYNAMODB_TABLE="payments"

#Cluster Variables
export CLUSTER_NAME="eks-demo-scale"
export K8sversion="1.28"

#Karpenter Variables
export KARPENTER_VERSION=v0.32.0

#KEDA Variables
export NAMESPACE=keda
export SERVICE_ACCOUNT=keda-service-account
export IAM_KEDA_ROLE="keda-demo-role"
export IAM_KEDA_SQS_POLICY="keda-demo-sqs"
export IAM_KEDA_DYNAMO_POLICY="keda-demo-dynamo"
export SQS_QUEUE_NAME="keda-demo-queue.fifo"
export SQS_QUEUE_URL="https://sqs.${AWS_REGION}.amazonaws.com/${ACCOUNT_ID}/${SQS_QUEUE_NAME}"
export SQS_TARGET_DEPLOYMENT="sqs-app"
export SQS_TARGET_NAMESPACE="keda-test"

# echo colour
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
BLUE=$(tput setaf 4)
NC=$(tput sgr0)