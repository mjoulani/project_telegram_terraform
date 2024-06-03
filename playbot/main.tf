# subfolder main.tf 

# Run the key generation script
# resource "null_resource" "generate_keys" {
#   provisioner "local-exec" {
#     command = "bash ${path.module}/generate_keys.sh"
#   }
# }

# # Import the first key
# resource "aws_key_pair" "my_key_1" {
#   depends_on = [null_resource.generate_keys]
#   key_name   = "my-key-1"
#   public_key = file("${path.module}/keys/my-key-1.pub")
# }




# resource "aws_instance" "muh_ec2_one" {
#   ami           = lookup(var.regions_list, var.region_aws, "default_value")
#   instance_type = "t2.micro"
#   iam_instance_profile   = var.instance_profile_name
#   vpc_security_group_ids = [var.security_group_id]
#   subnet_id              = var.subnet_id
#   associate_public_ip_address = true
#   user_data = file("${path.module}/setup.sh")
#   key_name                     = aws_key_pair.my_key_1.key_name
#   tags = {
#     Name = "muh_ec2_one"
#   }
# }

# subfolder main.tf

# Run the key generation script
# subfolder playbot main.tf

# Import the key from the variable



resource "aws_instance" "muh_ec2_one" {
  ami           = lookup(var.regions_list, var.region_aws, "default_value")
  instance_type = "t2.micro"
  iam_instance_profile   = var.instance_profile_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id[0]
  #subnet_id              = aws_subnet.muh_bot_public_subnets[0].id
  associate_public_ip_address = true
  user_data = file("${path.module}/setup.sh")
  key_name  = var.key_name
  #key_name  = aws_key_pair.my_key_1.key_name
  tags = {
    Name = "muh_ec2_one" 
  }
  root_block_device {
    volume_size = 30  # Size in GB
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "optional"
  }
}

resource "aws_instance" "muh_ec2_two" {
  ami           = lookup(var.regions_list, var.region_aws, "default_value")
  instance_type = "t2.micro"
  iam_instance_profile   = var.instance_profile_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id[1]
  #subnet_id              = aws_subnet.muh_bot_public_subnets[1].id  # Use the second subnet from your list
  associate_public_ip_address = true
  user_data = file("${path.module}/setup.sh")
  #key_name  = aws_key_pair.my_key_1.key_name
  key_name  = var.key_name
  tags = {
    Name = "muh_ec2_two" 
  }
  root_block_device {
    volume_size = 30  # Size in GB
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "optional"
  }
}

# data "template_file" "setup_additional" {
#   template = file("${path.module}/setup_additional.tpl")
#   #template = file("./setup_additional.tpl")
#   vars = {
#     aws_region = var.region_aws
#     telegram_token = var.telegram_token
#     # Add other variables here as needed
#   }
# }
resource "null_resource" "run_setup_additional_one" {
  depends_on = [aws_instance.muh_ec2_one]

  # provisioner "file" {
  #   source      = data.template_file.setup_additional.rendered
  #   destination = "/home/ubuntu/setup_additional.sh"
  # }

  connection {
    type        = "ssh"
    host        = aws_instance.muh_ec2_one.public_ip
    user        = "ubuntu"
    private_key = file("my-key-1.pem")
  }
  provisioner "file" {
    source      = "${path.module}/setup_additional.sh"
    destination = "/home/ubuntu/setup_additional.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'export AWS_REGION=${var.region_aws}' >> ~/.bashrc",
      "echo 'export Telegram_token=${var.telegram_token}' >> ~/.bashrc",
      "echo 'export Telegram_url=${var.telegram_url}' >> ~/.bashrc",
      "echo 'export SQS_QUEUE_NAME=${var.sqs_queue_name}' >> ~/.bashrc",
      "echo 'export S3_BUCKET_NAME=\"${var.s3_bucket_name}\"' >> ~/.bashrc",
      "env_file='env_variables.txt'",
      "echo 'Telegram_token=${var.telegram_token}' >> $env_file",
      "echo 'AWS_REGION=${var.region_aws}' >> $env_file",
      "echo 'SQS_QUEUE_NAME=${var.sqs_queue_name}' >> $env_file",
      "echo 'S3_BUCKET_NAME=\"${var.s3_bucket_name}\"' >> $env_file",
      "echo 'Telegram_url=\"${var.telegram_url}\"' >> $env_file"
    ]
  }
}
resource "null_resource" "run_setup_additional_two" {
  depends_on = [aws_instance.muh_ec2_two]

  # provisioner "file" {
  #   source      = data.template_file.setup_additional.rendered
  #   destination = "/home/ubuntu/setup_additional.sh"
  # }

  connection {
    type        = "ssh"
    host        = aws_instance.muh_ec2_two.public_ip
    user        = "ubuntu"
    private_key = file("my-key-1.pem")
  }
  provisioner "file" {
    source      = "${path.module}/setup_additional.sh"
    destination = "/home/ubuntu/setup_additional.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'export AWS_REGION=${var.region_aws}' >> ~/.bashrc",
      "echo 'export Telegram_token=${var.telegram_token}' >> ~/.bashrc",
      "echo 'export SQS_QUEUE_NAME=${var.sqs_queue_name}' >> ~/.bashrc",
      "echo 'export S3_BUCKET_NAME=\"${var.s3_bucket_name}\"' >> ~/.bashrc",
      "echo 'export Telegram_url=${var.telegram_url}' >> ~/.bashrc",
      "env_file='env_variables.txt'",
      "echo 'Telegram_token=${var.telegram_token}' >> $env_file",
      "echo 'AWS_REGION=${var.region_aws}' >> $env_file",
      "echo 'SQS_QUEUE_NAME=${var.sqs_queue_name}' >> $env_file",
      "echo 'S3_BUCKET_NAME=\"${var.s3_bucket_name}\"' >> $env_file",
      "echo 'Telegram_url=\"${var.telegram_url}\"' >> $env_file"
    ]
  }
}


