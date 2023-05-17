import boto3
import json
import time
from datetime import datetime
# create a function to add numbers

queue_url = "https://sqs.us-west-1.amazonaws.com/809980971988/karpenter-queue.fifo"

def send_message(message_body):
    print("Start fn send message")
    sqs_client = boto3.client("sqs", region_name="us-west-1")    
    response = sqs_client.send_message(
    QueueUrl = queue_url,
    MessageBody = message_body,
    MessageGroupId='messageGroup1'
    )
    print(f"messages send: {response}")

    print("End fn send message")

starttime = time.time()
i = 0
while True:
    t = time.localtime()
    time.sleep(1.0 - ((time.time() - starttime) % 1.0))
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"Start SQS Call : {currenttime}")    
    #while i < 20:
    i = i+1
    date_format = '%Y-%m-%d %H:%M:%S.%f'
    current_dateTime = datetime.utcnow().strftime(date_format)
    messageBody = {
        'msg':f"Scale Buddy !!! : COUNT {i}",
        'srcStamp': current_dateTime
    }
    print(json.dumps(messageBody))
    send_message(json.dumps(messageBody))
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"End SQS Call {currenttime}")
    #time.sleep(5)
