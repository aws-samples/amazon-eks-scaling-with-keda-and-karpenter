#******************
# Clean Deployment
#******************
echo "${RED}******************************************************"
echo "${RED}**************CLEANUP START***************************"
echo "${RED}******************************************************"
echo "${CYAN}Load variables"
source ./deployment/environmentVariables.sh

echo "${RED}Find all CFN stack names which has cluster name"
for stack in $(aws cloudformation describe-stacks  --region ${AWS_REGION} --output text --query 'Stacks[?StackName!=`null`]|[?contains(StackName, `'${CLUSTER_NAME}'`) == `true`].StackName')
do 
SUB='nodegroup'
if [[ "$stack" == *"$SUB"* ]]; then
  echo "${RED}Deleting stacks : ${stack}"
  echo "Node group"
  aws cloudformation delete-stack --stack-name $stack --region ${AWS_REGION}
  aws cloudformation wait stack-delete-complete  --region ${AWS_REGION}  --stack-name $stack
else
  echo "${RED}Deleting stacks : ${stack}"
  echo "other stack" 
  aws cloudformation delete-stack --stack-name $stack --region ${AWS_REGION}
    aws cloudformation wait stack-delete-complete  --region ${AWS_REGION}  --stack-name $stack
fi
done

# Delete IAM Roles
echo "${RED}Deleting Role"

for policy in $(aws iam list-attached-role-policies --role-name ${IAM_KEDA_ROLE} --output text --query 'AttachedPolicies[*].PolicyName')
do
echo "${RED}Detach policy :${policy} from role :${IAM_KEDA_ROLE}"
aws iam detach-role-policy --role-name ${IAM_KEDA_ROLE} --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${policy}

echo "${RED}Deleting policy :${policy}"
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${policy}
done

echo "${RED}Deleting role : ${IAM_KEDA_ROLE}"
aws iam delete-role --role-name ${IAM_KEDA_ROLE}

echo "${RED}Delete IAM policies, if missed earlier"
# Delete IAM policies
#Deleting the policies if missed during role deletion process

isSQSPolicyExist=$(aws iam list-policies --output text --query 'Policies[?PolicyName==`'${IAM_KEDA_SQS_POLICY}'`].PolicyName')
echo $isSQSPolicyExist
if [ ! -z $isSQSPolicyExist ];then
echo "${RED}Deleting policy :"$IAM_KEDA_SQS_POLICY
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${IAM_KEDA_SQS_POLICY}
else
echo "policy ${IAM_KEDA_SQS_POLICY} already deleted"
fi

isDynamoPolicyExist=$(aws iam list-policies --output text --query 'Policies[?PolicyName==`'${IAM_KEDA_DYNAMO_POLICY}'`].PolicyName')
echo $isDynamoPolicyExist
if [ ! -z $isDynamoPolicyExist ];then
echo "${RED}Deleting policy :"$IAM_KEDA_DYNAMO_POLICY
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${IAM_KEDA_DYNAMO_POLICY}
else
echo "policy ${IAM_KEDA_DYNAMO_POLICY} already deleted"
fi


SQS_URL=$(aws sqs get-queue-url --queue-name ${SQS_QUEUE_NAME} --output text)
if [ ! -z $SQS_URL ];then
echo "${RED}Deleting SQS :"$SQS_URL
aws sqs delete-queue --queue-url $SQS_URL --region ${AWS_REGION}

fi

DYNAMO_TABLE=$(aws dynamodb describe-table  --table-name ${DYNAMODB_TABLE} --region ${AWS_REGION} --query 'Table.TableName' --output text)
if [ ! -z $DYNAMO_TABLE ];then
echo "${RED}Deleting DynamoTable :"$DYNAMO_TABLE
RESPONSE=$(aws dynamodb delete-table --table-name $DYNAMO_TABLE --region ${AWS_REGION} --output text)
echo $RESPONSE
fi
#******************
# Clean Completed
#******************
echo "${GREEN}******************************************************"
echo "${GREEN}**************CLEANUP COMPLETE************************"
echo "${GREEN}******************************************************"