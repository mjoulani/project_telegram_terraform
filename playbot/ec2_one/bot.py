import telebot
from loguru import logger
import os
import json
import time
import boto3
from telebot.types import InputFile

bucket_name = os.environ['S3_BUCKET_NAME']
queue_name = os.environ['SQS_QUEUE_NAME']
region_name = os.environ['AWS_REGION']

logger.info(f'BUCKET NAME =  {bucket_name}')
logger.info(f'QUEUE NAME =  {queue_name}')
logger.info(f'REGION NAME =  {region_name}')

class Bot:

    def __init__(self, token, telegram_chat_url):
        # create a new instance of the TeleBot class.
        # all communication with Telegram servers are done using self.telegram_bot_client
        self.telegram_bot_client = telebot.TeleBot(token)

        # remove any existing webhooks configured in Telegram servers
        self.telegram_bot_client.remove_webhook()
        time.sleep(0.5)

        # set the webhook URL
        self.telegram_bot_client.set_webhook(url=f'{telegram_chat_url}/{token}/')

        logger.info(f'Telegram Bot information\n\n{self.telegram_bot_client.get_me()}')

    def send_message_to_sqs(self, message_body):
        # Create an SQS client
        sqs_client = boto3.client('sqs', region_name=region_name)

        # Get the URL of the queue
        response = sqs_client.get_queue_url(QueueName=queue_name)
        sqs_url = response['QueueUrl']

        # Send a message to the queue
        response = sqs_client.send_message(QueueUrl=sqs_url, MessageBody=message_body)

        return response

    def send_text(self, chat_id, text):
        self.telegram_bot_client.send_message(chat_id, text)

    def send_photo_rep(self, chat_id, file_path, msg=None):
        try:
            with open(file_path, 'rb') as photo_file:
                self.telegram_bot_client.send_photo(chat_id, photo=photo_file)
                photo_file.close()
        except Exception as e:
            logger.error(f'Error sending photo: {e}')
        else:
             logger.info(f'Successfully sent photo to chat ID {chat_id}')
        return None


    def send_text_with_quote(self, chat_id, text, quoted_msg_id):
        self.telegram_bot_client.send_message(chat_id, text, reply_to_message_id=quoted_msg_id)

    def is_current_msg_photo(self, msg):
        return 'photo' in msg

    def download_user_photo(self, msg):
        """
        Downloads the photos that sent to the Bot to `photos` directory (should be existed)
        :return:
        """
        if not self.is_current_msg_photo(msg):
            # If the message does not contain a photo, send a response and return
            text = "Please upload a photo."
            self.send_text(msg['chat']['id'], text)
            return None

        file_info = self.telegram_bot_client.get_file(msg['photo'][-1]['file_id'])
        data = self.telegram_bot_client.download_file(file_info.file_path)
        folder_name = file_info.file_path.split('/')[0]

        if not os.path.exists(folder_name):
            os.makedirs(folder_name)


        with open(file_info.file_path, 'wb') as photo:
            photo.write(data)

        return file_info.file_path

    def send_photo(self, chat_id, img_path):
        if not os.path.exists(img_path):
            raise RuntimeError("Image path doesn't exist")

        self.telegram_bot_client.send_photo(
            chat_id,
            InputFile(img_path)
        )

    def handle_message(self, msg):
        """Bot Main message handler"""
        logger.info(f'Incoming message: {msg}')
        if 'text' in msg:
            # If the message contains text, send a response based on the text
            self.send_text(msg['chat']['id'], f'Your original message: {msg["text"]}')
        elif 'photo' in msg:
            # If the message contains a photo, download and process the photo
            img_path = self.download_user_photo(msg)
            logger.info(f'Downloaded photo to {img_path}')
            # Process the photo...
        else:
            # If the message contains other types of content, handle it accordingly
            # For example, you can send a default response or ignore the message
            self.send_text(msg['chat']['id'], 'Unsupported message type')


class ObjectDetectionBot(Bot):
   def handle_message(self, msg):
        """Bot Main message handler"""
        logger.info(f'Incoming message: {msg}')
        img_path = self.download_user_photo(msg)
        if img_path:
            # Photo downloaded successfully, proceed with upload
            s3 = boto3.client('s3')
            # bucket_name = 'mjoulani-bucket'
            s3.upload_file(img_path, bucket_name, os.path.basename(img_path))
            logger.info(f'Uploaded photo to S3')

            message_body = json.dumps([os.path.basename(img_path),msg['chat']['id']])

            response = self.send_message_to_sqs(message_body)
            logger.info('The SQS response : {response}')
            temp = json.loads(message_body)
            text = f' Your image {temp[0]} is being processed. Please wait...'
            self.send_text(msg['chat']['id'], text)
        else:
            # Photo download failed, handle accordingly
            logger.info('Failed to download photo from the message.')
