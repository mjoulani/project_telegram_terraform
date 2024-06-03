#!/bin/bash

# Update and upgrade the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install necessary dependencies
sudo apt-get install -y unzip curl

# Install Docker
sudo apt-get install -y docker.io

# Add the current user to the Docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker ubuntu  # Adding default Ubuntu user as well

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Install AWS CLI using the bundled installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install



