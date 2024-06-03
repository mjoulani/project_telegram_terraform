# provider "aws" {
#   region = "us-west-2"  # Update with your desired region
# }

# # Define the IAM role
# resource "aws_iam_role" "full_access_role" {
#   name               = "full_access_role"
#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "ec2.amazonaws.com"
#         },
#         "Action" : "sts:AssumeRole"
#       },
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "lambda.amazonaws.com"
#         },
#         "Action" : "sts:AssumeRole"
#       },
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service": "events.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#       }
#     ]
#   })
# }

# # Attach policies granting full access to EC2, SQS, Lambda, and EventBridge
# resource "aws_iam_role_policy_attachment" "ec2_full_access_policy" {
#   role       = aws_iam_role.full_access_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
# }

# resource "aws_iam_role_policy_attachment" "sqs_full_access_policy" {
#   role       = aws_iam_role.full_access_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
# }

# resource "aws_iam_role_policy_attachment" "lambda_full_access_policy" {
#   role       = aws_iam_role.full_access_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
# }

# resource "aws_iam_role_policy_attachment" "eventbridge_full_access_policy" {
#   role       = aws_iam_role.full_access_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
# }

# # Attach the role to your EC2 instance
# resource "aws_iam_instance_profile" "instance_profile" {
#   name = "ec2_instance_profile"
#   role = aws_iam_role.full_access_role.name
# }

# # Attach the role to your Lambda function (replace "your_lambda_function_name")
# resource "aws_lambda_function" "example_lambda" {
#   function_name    = "your_lambda_function_name"
#   role             = aws_iam_role.full_access_role.arn
#   # Other lambda function configuration...
# }

# # Attach the role to your SQS queue (replace "your_sqs_queue_url")
# resource "aws_sqs_queue_policy" "sqs_queue_policy" {
#   queue_url = "your_sqs_queue_url"
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : "*",
#         "Action" : "SQS:*",
#         "Resource" : "*"
#       }
#     ]
#   })
# }

# # Attach the role to EventBridge
# resource "aws_cloudwatch_event_target" "event_target" {
#   rule = "your_event_rule_name"
#   arn  = aws_iam_role.full_access_role.arn
# }
