# subfolder playbot veriable.file
variable "regions_list" {
  type = map(string)
}

variable "region_aws" {
  type        = string
}

variable "instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile"
}

variable "security_group_id" {
  type = string
}

variable "subnet_id" {
  type = list(string)
}

variable "telegram_token" {
  type = string
}
variable "key_name" {
  
}

variable "sqs_queue_name" {
  type = string
}
variable "s3_bucket_name" {
  type = string
}
variable "telegram_url" {
  type = string
}