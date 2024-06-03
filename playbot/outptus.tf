output "ec2_public_ip" {
  value = aws_instance.muh_ec2_one.public_ip
}

# Output the key file name
output "key_file_name" {
  value = var.key_name
}