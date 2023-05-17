#******************
# Deploy AWS Services
#******************
echo "${BLUE} Start deploying Dynamo & SQS"

source ./deployment/environmentVariables.sh


echo "${GREEN} Deploy Dynamo"
Dynamo=$(aws dynamodb create-table \
    --table-name ${DYNAMODB_TABLE} --region ${AWS_REGION} \
    --attribute-definitions AttributeName=id,AttributeType=S             AttributeName=messageProcessingTime,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH AttributeName=messageProcessingTime,KeyType=RANGE \
    --billing-mode PROVISIONED \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1  --output text)
echo "${GREEN} DynamoInstance : ${Dynamo}"

echo "${GREEN} Deploy SQS"
SQS=$(aws sqs create-queue --queue-name ${SQS_QUEUE_NAME} --region ${AWS_REGION} \
--attributes FifoQueue=true,VisibilityTimeout=3600,MessageRetentionPeriod=345600,ContentBasedDeduplication=true)
echo "${GREEN} SQSInstance : ${SQS}"

echo "${GREEN} End deploying Dynamo & SQS"