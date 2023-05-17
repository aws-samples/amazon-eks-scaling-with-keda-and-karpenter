import boto3
import json
import time
from datetime import datetime
import os
from os import environ
import subprocess



if 'SQS_QUEUE_URL' in os.environ:
    queue_url = os.environ['SQS_QUEUE_URL']
    print (f'SQS URL : {queue_url}')
else:
    print ('SQS URL Missing!!!!!')

def send_message(message_body):
    print("Start fn send message")
    sqs_client = boto3.client("sqs", region_name=os.environ['AWS_REGION'])    
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
    if 'SQS_QUEUE_URL' in os.environ:
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
    else:
        print ("SQS URL missing from environment. Run environmentVariables.sh first ")