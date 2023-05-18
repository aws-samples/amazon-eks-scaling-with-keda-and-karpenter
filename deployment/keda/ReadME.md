
## Update KEDA configuration 

environmentVariables.sh file in /deployment


| Variable Name               | Description                                                                                         |
|-----------------------------|-----------------------------------------------------------------------------------------------------|
| `NAMESPACE`                 | The Kubernetes namespace for KEDA.                                                                  |
| `SERVICE_ACCOUNT`           | The Kubernetes service account for KEDA.                                                            |
| `IAM_KEDA_ROLE`             | The IAM role for KEDA.                                                                              |
| `IAM_KEDA_SQS_POLICY`       | The IAM policy for KEDA to access SQS.                                                              |
| `IAM_KEDA_DYNAMO_POLICY`    | The IAM policy for KEDA to access DynamoDB.                                                         |
| `SQS_QUEUE_NAME`            | The name of the SQS queue.                                                                          |
| `SQS_QUEUE_URL`             | The URL of the SQS queue.                                                                           |
| `SQS_TARGET_DEPLOYMENT`     | The target deployment for KEDA to scale based on SQS messages.                                      |
| `SQS_TARGET_NAMESPACE`      | The target namespace for the deployment that KEDA scales based on SQS messages.                     |
