import time
import sys
from pathlib import Path
from detect import run
from decimal import Decimal
import yaml
from loguru import logger
import os
import boto3
import json
import time
import sys
import requests

# Function to send a GET request to an EC2 instance
def send_request_to_instance(ip,prediction_id):
    url = f"http://{ip}:{port}/results?predictionId={prediction_id}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            logger.info(f"Request successful to {url}")
            logger.info(f"Response content: {response.content}")
            return True

        else:
            logger.info(f"Request failed to {url}: {response.status_code}")
            return False

    except requests.RequestException as e:
        logger.info(f"Request failed to {url}: {str(e)}")
        return False





images_bucket = os.environ['S3_BUCKET_NAME']
queue_name = os.environ['SQS_QUEUE_NAME']
region_name = os.environ['AWS_REGION']

# Define the IP addresses and ports of your EC2 instances
ec2_muh1_ip = os.environ['EC2_ONE_IP']
ec2_muh2_ip = os.environ['EC2_TWO_IP']
port = 8443


logger.info(f'BUCKET NAME =  {images_bucket}')
logger.info(f'QUEUE NAME =  {queue_name}')
logger.info(f'REGION NAME =  {region_name}')
logger.info(f'ec2_muh1_ip =  {ec2_muh1_ip}')
logger.info(f'ec2_muh2_ip  =  {ec2_muh2_ip}')
logger.info(f'port  =  {port}')


sqs_client = boto3.client('sqs', region_name=region_name)
with open("data/coco128.yaml", "r") as stream:
    names = yaml.safe_load(stream)['names']


def consume():
    while True:
        response = sqs_client.receive_message(QueueUrl=queue_name, MaxNumberOfMessages=1, WaitTimeSeconds=5)

        if 'Messages' in response:
            message = response['Messages'][0]['Body']
            receipt_handle = response['Messages'][0]['ReceiptHandle']

            # Use the ReceiptHandle as a prediction UUID
            prediction_id = response['Messages'][0]['MessageId']

            logger.info(f'prediction: {prediction_id}. start processing')

            # Receives a URL parameter representing the image to download from S3
            message_list = json.loads(message)
            img_name = message_list[0]  # TODO extract from `message`
            chat_id = message_list[1]  # TODO extract from `message`
            logger.info(f'image_name =  {img_name}')
            logger.info(f'chat_id =  {chat_id}')

            original_img_path = '/usr/src/app/'
            s3 = boto3.client('s3')
            s3.download_file(images_bucket, img_name, os.path.join(original_img_path, img_name))
            original_img_path = os.path.join(original_img_path, img_name)
            logger.info(f'prediction: {prediction_id}/{original_img_path}. Download img completed')

            # Predicts the objects in the image
            run(
                weights='yolov5s.pt',
                data='data/coco128.yaml',
                source=original_img_path,
                project='static/data',
                name=prediction_id,
                save_txt=True
            )

            logger.info(f'prediction: {prediction_id}/{original_img_path}. done')

            # This is the path for the predicted image with labels
            predicted_img_path = Path(f'static/data/{prediction_id}/{img_name}')
            the_image = img_name[:-4] + "_predicted.jpg"
            s3.upload_file(str(predicted_img_path), images_bucket, the_image)

            # Parse prediction labels and create a summary
            pred_summary_path = Path(f'static/data/{prediction_id}/labels/{Path(original_img_path).stem}.txt')
            logger.info(f'pred_summary_path : {pred_summary_path}')
            if pred_summary_path.exists():
                with open(pred_summary_path) as f:
                    labels = f.read().splitlines()
                    labels = [line.split(' ') for line in labels]
                    labels = [{
                        'class': names[int(l[0])],
                        'cx': Decimal(l[1]),  # Convert float to Decimal
                        'cy': Decimal(l[2]),  # Convert float to Decimal
                        'width': Decimal(l[3]),  # Convert float to Decimal
                        'height': Decimal(l[4])  # Convert float to Decimal
                    } for l in labels]

                logger.info(f'******prediction: {prediction_id}/{original_img_path}. prediction summary:\n\n{labels}')

                prediction_summary = {
                    'prediction_id': str(prediction_id),
                    'original_img_path': original_img_path,
                    'predicted_img_path': str(predicted_img_path),
                    'labels': labels,
                    'chat_id': chat_id
                }

                # Store data in DynamoDB
                dynamodb_resource = boto3.resource('dynamodb', region_name=region_name)
                table_name = 'prediction_summary'
                table = dynamodb_resource.Table(table_name)

                table.put_item(Item=prediction_summary)
                logger.info("Data stored successfully.")

                #sqs_client.delete_message(QueueUrl=queue_name, ReceiptHandle=receipt_handle)

                try:
                # Delete the message from the SQS queue
                    response = sqs_client.delete_message(
                    QueueUrl=queue_name,
                    ReceiptHandle=receipt_handle
                )

                # If no exception is raised, the deletion was successful
                    logger.info("Message deleted successfully.")
                except sqs_client.exceptions.QueueDoesNotExist:
                    logger.info("The specified queue does not exist.")
                except sqs_client.exceptions.ReceiptHandleIsInvalid:
                    logger.info("The specified receipt handle is invalid.")
                except Exception as e:
                    logger.info(f"An error occurred: {str(e)}")


                # Send requests to both EC2 instances
                connection = send_request_to_instance(ec2_muh1_ip,str(prediction_id))
                if not connection :
                   send_request_to_instance(ec2_muh2_ip,str(prediction_id))

                time.sleep(3)

            else:
                logger.info("path {pred_summary_path} dose not exists ")

if __name__ == "__main__":
    consume()
