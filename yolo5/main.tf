# subfolder yolo5 main.tf
# Import the key from the variable


resource "aws_instance" "muh_ec2_yolo5" {
  ami           = lookup(var.regions_list, var.region_aws, "default_value")
  instance_type = "t2.micro"
  iam_instance_profile   = var.instance_profile_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id
  associate_public_ip_address = true
  user_data              = file("${path.module}/setup.sh")
  #key_name               = aws_key_pair.my_key_1.key_name
  key_name  = var.key_name
  tags = {
    Name = "muh_ec2_yolo5" 
  }

    root_block_device {
    volume_size = 30  # Size in GB
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "optional"
  }
}

resource "null_resource" "run_setup_additional" {
  depends_on = [aws_instance.muh_ec2_yolo5]

  connection {
    type        = "ssh"
    host        = aws_instance.muh_ec2_yolo5.public_ip
    user        = "ubuntu"
    private_key = file("my-key-1.pem")
    #private_key = file("C:/jenkins_ec2_new/my-key-1.pem")
  }

  provisioner "file" {
    source      = "${path.module}/setup_additional.sh"
    destination = "/home/ubuntu/setup_additional.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_additional.sh", # Add execute permission to the script
      "/home/ubuntu/setup_additional.sh"  # Pass both region and SQS queue name as arguments
    ]
  }
}









