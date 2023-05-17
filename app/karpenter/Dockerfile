FROM ubuntu:latest

RUN apt-get update
RUN apt update

RUN apt install python3 -y
RUN apt install -y python3-pip
RUN pip3 install --upgrade pip
RUN  pip install boto3  

WORKDIR /usr/app/src

COPY karpenter-sqs-reader.py ./

CMD [ "python3", "./karpenter-sqs-reader.py" ]