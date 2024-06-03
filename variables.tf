#          variable.tf

variable "region_aws" {
  type        = string
  description = "region to chocie"
}

/*------------------------------vpc variable------------------------*/
variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  #default = "muh_telegram_bot"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
 #default = "11.0.0.0/16"
}

/*-------------------------------subnet variable-----------------------------------*/
variable "cidr_public_subnet" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

/*----------------------------------security group--------------------------------*/
variable "ports" {
  description = "List of ports for the security group rules"
  type        = list(number) 
}

variable "types" {
  description = "List of protocols for the security group rules"
  type        = list(string) 
}
/*--------------------------------Ec2 variable module---------------------------------------------*/
variable "regions_list" {
  type = map(string)
  default = {
    "us-east-1"    = "ami-04b70fa74e45c3917"
    "ap-south-1"   = "ami-0f58b397bc5c1f2e8"
    "eu-central-1" = "ami-01e444924a2233b07"
    "eu-west-1"    = "ami-0776c814353b4814d"
    "sa-east-1"    = "ami-04716897be83e3f04"
  }
}
variable "telegram_token" {
  type = string
}

variable "telegram_url" {
  type = string
}
# variable "sqs_queue_name" {
#   type = string
# }
# variable "s3_bucket_name" {
#   type = string
# }
# variable "instance_profile_name" {
#   type        = string
#   description = "Name of the IAM instance profile"
# }





