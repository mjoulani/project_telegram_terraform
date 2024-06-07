# main folder outputs.tf
output "aws" {
  value = var.region_aws
}
output "instance_profile_name" {
  value = aws_iam_instance_profile.instance_profile.name
}

output "security_group_id" {
  value = aws_security_group.muh_bot_security_group.id
}

output "subnet_id" {
  value = aws_subnet.muh_bot_public_subnets[0].id
}

output "subnet_id_2" {
  value = aws_subnet.muh_bot_public_subnets[1].id
}

output "sqs_queue_name" {
  value = aws_sqs_queue.muh_bot_sqs.name
}

# output "ec2_public_ip" {
#   value = module.yolo5.ec2_public_ip
# }
output "yolo5_ec2_public_ip" {
  value = module.yolo5.ec2_public_ip
}

output "playbot_ec2_public_ips" {
  value = module.playbot.ec2_public_ips
}





