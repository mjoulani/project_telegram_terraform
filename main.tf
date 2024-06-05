# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }


# }

# provider "aws" {
#   region                   = var.region_aws
#   #shared_credentials_files = ["C:\\Users\\muham.DESKTOP-T5LGP3O\\.aws\\credentials"]
# }

# resource "aws_s3_bucket" "example" {
#   bucket = "muh-tfstate-bucket"  # Corrected bucket name

#   tags = {
#     Name        = "My bucket"
#     Environment = "terraform state file"
#   }
# }

# resource "aws_dynamodb_table" "tfstate_tf_lockid" {
#   name           = "tfstate_tf_lockid"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 5
#   write_capacity = 5
#   hash_key       = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }

#                   code maint.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "muh-tfstate-bucket"
    key            = "state/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "tfstate_tf_lockid"
  }
}

provider "aws" {
  region                   = var.region_aws
  shared_credentials_files = ["C:\\Users\\muham.DESKTOP-T5LGP3O\\.aws\\credentials"]
}

resource "aws_key_pair" "my_key_1" {
  key_name   = "my-key-1"
  public_key = file("my-key-1.pub")
  tags = { Name = "my_key_1" }
}


/*creating vpc and subnet and getway and routertable and role*/
/*------------------------VPC--------------------------------*/

# Calculate availability zones based on region
locals {
  get_availability_zones = [for az_suffix in ["b", "c"] : "${var.region_aws}${az_suffix}"]
}

# Setup VPC
resource "aws_vpc" "muh_bot" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

/*------------------------public subnet---------------*/

# Setup public subnet
resource "aws_subnet" "muh_bot_public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.muh_bot.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = local.get_availability_zones[count.index]

  tags = {
    Name = "muh-bot-public-subnet-${count.index + 1}"
  }
}

/*-----------------------Gatway-------------------------*/

# Setup Internet Gateway
resource "aws_internet_gateway" "muh_bot_public_internet_gateway" {
  vpc_id = aws_vpc.muh_bot.id
  tags = {
    Name = "muh-bot-igw"
  }
}

/*------------------------Public Route Table----------------------*/

# Setup Public Route Table
resource "aws_route_table" "muh_bot_public_route_table" {
  vpc_id = aws_vpc.muh_bot.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.muh_bot_public_internet_gateway.id
  }
  tags = {
    Name = "muh-bot-public-route-table"
  }
}
/*--------Public Route Table and Public Subnet Association--------*/

# Public Route Table and Public Subnet Association
resource "aws_route_table_association" "muh_bot_subnet_association" {
  count          = length(aws_subnet.muh_bot_public_subnets)
  subnet_id      = aws_subnet.muh_bot_public_subnets[count.index].id
  route_table_id = aws_route_table.muh_bot_public_route_table.id
}

/*----------------------security group genarelly use--------------*/
# Setup security gruop
resource "aws_security_group" "muh_bot_security_group" {
  name =   "muh_bot_security_group"
  description = "Security group with dynamic ports and protocal"
  vpc_id = aws_vpc.muh_bot.id

  dynamic "ingress" {
    for_each = zipmap(var.ports, var.types)
    content {
      from_port = ingress.key
      to_port   = ingress.key
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      #type = ingress.value
      description = ingress.value
    }
  }
  egress{
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  } 
  
}
/*---------------------------------Creating SQS---------------------*/

# Create a standard SQS queue
# Create a standard SQS queue
resource "aws_sqs_queue" "muh_bot_sqs" {
  name                      = "muh_bot_sqs"  # Queue name
  delay_seconds             = 90  # Example delay time in seconds
  max_message_size          = 2048  # Example max message size in bytes
  message_retention_seconds = 345600  # Example message retention period in seconds (4 days)
  visibility_timeout_seconds = 30  # Example visibility timeout in seconds
  receive_wait_time_seconds = 10  # Example receive wait time in seconds
  tags = {
    Name = "muh-bot-sqs"
  }
}

# Attach the police to the SQS queue
resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.muh_bot_sqs.id  # Use the queue ID
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "SQS:*",
        "Resource" : "*"
      }
    ]
  })
}

/*********************************Creating role*************************/
# Define the IAM role

resource "aws_iam_role" "full_access_role" {
  name               = "full_access_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service": "events.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies granting full access to EC2, SQS, Lambda, and EventBridge
# Attach the AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "full_access_role_admin_policy" {
  role       = aws_iam_role.full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_role_policy_attachment" "ec2_full_access_policy" {
  role       = aws_iam_role.full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_full_access_policy" {
  role       = aws_iam_role.full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_policy" {
  role       = aws_iam_role.full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_role_policy_attachment" "eventbridge_full_access_policy" {
  role       = aws_iam_role.full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

/*--------------------------------S3 module----------------------------------*/
resource "aws_s3_bucket" "muh-bucket" {
  bucket = "mjoulani-bucket-s3"
  tags = {
    Name        = "mjoulani-bucket"
  }
}

# resource "aws_s3_bucket_policy" "muh_bucket_policy" {
#   bucket = aws_s3_bucket.muh-bucket.id

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": "${aws_iam_role.full_access_role.arn}"
#         },
#         "Action": "s3:*",
#         "Resource": [
#           "${aws_s3_bucket.muh-bucket.arn}",
#           "${aws_s3_bucket.muh-bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }
/*-------------------------dymamody--------------------------------------------*/
resource "aws_dynamodb_table" "prediction_summary" {
  name           = "prediction_summary"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "primary_key"

  attribute {
    name = "primary_key"
    type = "S"
  }
  tags = {
    Name = "prediction_summary"
  }
}



/*--------------------------------Ec2 module----------------------------------*/

# Define the IAM instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.full_access_role.name
}

# output "instance_profile_name" {
#   value = aws_iam_instance_profile.instance_profile.name
# }

# output "security_group_id" {
#   value = aws_security_group.muh_bot_security_group.id
# }

# output "subnet_id" {
#   value = aws_subnet.muh_bot_public_subnets[0].id
# }

module "playbot" {
  source = "./playbot"
  regions_list = var.regions_list
  region_aws   = var.region_aws
  telegram_token        = var.telegram_token
  telegram_url          = var.telegram_url
  sqs_queue_name        = aws_sqs_queue.muh_bot_sqs.name
  s3_bucket_name         = aws_s3_bucket.muh-bucket.bucket
  instance_profile_name = aws_iam_instance_profile.instance_profile.name
  security_group_id     = aws_security_group.muh_bot_security_group.id
  subnet_id             = aws_subnet.muh_bot_public_subnets[*].id
  key_name              = aws_key_pair.my_key_1.key_name

  #depends_on = [aws_s3_bucket.muh-bucket, aws_s3_bucket_policy.muh_bucket_policy]   
}

module "yolo5" {
  source = "./yolo5"
  regions_list = var.regions_list
  region_aws   = var.region_aws
  instance_profile_name = aws_iam_instance_profile.instance_profile.name
  security_group_id     = aws_security_group.muh_bot_security_group.id
  subnet_id             = aws_subnet.muh_bot_public_subnets[0].id
  key_name              = aws_key_pair.my_key_1.key_name

  #depends_on = [aws_s3_bucket.muh-bucket, aws_s3_bucket_policy.muh_bucket_policy]  
}




# # Attach the role to your Lambda function (replace "your_lambda_function_name")
# resource "aws_lambda_function" "example_lambda" {
#   function_name    = "your_lambda_function_name"
#   role             = aws_iam_role.full_access_role.arn
#   # Other lambda function configuration...
# }



# Attach the role to EventBridge
# resource "aws_cloudwatch_event_target" "event_target" {
#   rule = "your_event_rule_name"
#   arn  = aws_iam_role.full_access_role.arn
# }



/*terraform apply -var-file='region.us-east-1.tfvars'*/




