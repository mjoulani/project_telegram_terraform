# subfolder yolo5 outputs.file

# outputs.tf (output variable definition)
output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.muh_ec2_yolo5.public_ip
}