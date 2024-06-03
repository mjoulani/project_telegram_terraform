#!/bin/bash

# Verify AWS CLI installation and wait until it's available
until aws --version &> /dev/null; do
    echo "Waiting for AWS CLI to be installed..."
    sleep 20
done

echo "AWS CLI is installed"

# Check if AWS CLI is installed and print its version
if command -v aws &> /dev/null; then
    echo "AWS CLI is installed"
    aws --version
else
    echo "AWS CLI is not installed"
    exit 1
fi

# Retrieve IP addresses of EC2 instances tagged with ec2_one and ec2_two
ec2_one_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=muh_ec2_one" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
ec2_two_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=muh_ec2_two" --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

# Retrieve the AWS region from the instance metadata
aws_region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Verify that the AWS region was retrieved successfully
if [ -z "$aws_region" ]; then
    echo "Failed to retrieve AWS region"
    exit 1
fi

# Retrieve the SQS queue name using the AWS CLI
sqs_queue_url=$(aws sqs list-queues --query "QueueUrls[?contains(@, 'muh_bot_sqs')]" --output text)
sqs_queue_name=$(echo "$sqs_queue_url" | awk -F'/' '{print $NF}')

# Retrieve the name of the S3 bucket
s3_bucket_name="mjoulani-bucket-s3"


# Set the IP addresses and region as environment variables in the current session
export EC2_ONE_IP=$ec2_one_ip
export EC2_TWO_IP=$ec2_two_ip
export AWS_REGION=$aws_region
export SQS_QUEUE_NAME=$sqs_queue_name
export S3_BUCKET_NAME="$s3_bucket_name"


# Persist the environment variables for future sessions
echo "export EC2_ONE_IP=$ec2_one_ip" >> ~/.bashrc
echo "export EC2_TWO_IP=$ec2_two_ip" >> ~/.bashrc
echo "export AWS_REGION=$aws_region" >> ~/.bashrc
echo "export SQS_QUEUE_NAME=$sqs_queue_name" >> ~/.bashrc
echo "export S3_BUCKET_NAME=$s3_bucket_name" >> ~/.bashrc

# Create a file with the environment variables for Docker
env_file="env_variables.txt"
echo "EC2_ONE_IP=$ec2_one_ip" > $env_file
echo "EC2_TWO_IP=$ec2_two_ip" >> $env_file
echo "AWS_REGION=$aws_region" >> $env_file
echo "SQS_QUEUE_NAME=$sqs_queue_name" >> $env_file
echo "S3_BUCKET_NAME=$s3_bucket_name" >> $env_file
