#!/bin/bash

# Define key pair names
KEY_NAME_1="my-key-1"
KEY_DIR="./playbot/keys"

# Ensure the directory exists
mkdir -p "${KEY_DIR}"

# Generate the first key pair
ssh-keygen -t rsa -b 4096 -f "${KEY_DIR}/${KEY_NAME_1}" -N ""

# Output the public key
cat "${KEY_DIR}/${KEY_NAME_1}.pub"

