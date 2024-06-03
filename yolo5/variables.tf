# subfolder yolo5 veriable.file
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
  type = string
}
variable "key_name" {
  
}


