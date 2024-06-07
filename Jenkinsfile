pipeline {
    agent any
    
    tools {
        terraform 'terraform_jenkins'
    }

    environment {
        TF_VAR_zone = "${params.zonechoice}"
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub')
        DOCKER_HUB_REPO = 'mjoulani'
        GIT_REPO_URL = 'https://github.com/mjoulani/project_telegram_terraform.git'
        THE_VALIE_NONE = credentials('aws_muh')
        TERRAFORM_OUTPUT = ''
    }

    parameters {
        choice choices: ['us-east-1', 'ap-south-1', 'eu-central-1', 'eu-west-1', 'sa-east-1'], description: 'Choice Zone', name: 'zonechoice'
        booleanParam(name: 'Init_TERRAFORM', defaultValue: false, description: 'Check to init Terraform changes')
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to destroy Terraform-managed infrastructure')
    }

    stages {
        stage('Clone Repository') {
            steps {
                deleteDir()
                sh 'ls -lart'
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[url: "${GIT_REPO_URL}"]]
                ]
                sh 'ls -lart'
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    def images = [
                        [name: 'playbot-ec2-one', context: 'playbot/ec2_one', dockerfile: 'playbot/ec2_one/Dockerfile'],
                        [name: 'playbot-ec2-two', context: 'playbot/ec2_two', dockerfile: 'playbot/ec2_two/Dockerfile'],
                        [name: 'yolo5-ec2', context: 'yolo5/ec2_yolo5', dockerfile: 'yolo5/ec2_yolo5/Dockerfile']
                    ]

                    for (image in images) {
                        def imageTag = "${DOCKER_HUB_REPO}/${image.name}:latest"

                        echo "Building Docker image: ${image.name}"
                        sh "docker build -t ${imageTag} -f ${image.dockerfile} ${image.context}"

                        echo "Pushing Docker image: ${image.name}"
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'DOCKERHUB_CREDENTIALS_PSW', usernameVariable: 'DOCKERHUB_CREDENTIALS_USR')]) {
                            sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                        }
                        sh "docker push ${imageTag}"
                    }
                }
            }
        }

        stage('Terraform Init') {
            when {
                expression { params.Init_TERRAFORM }
            }
            steps {
                script {
                    echo "=================Terraform Init=================="
                    echo "Choice : ${params.zonechoice}"
                    sh 'ls -lart'
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.PLAN_TERRAFORM }
            }
            steps {
                script {
                    echo "=================Terraform Plan=================="
                    def tokens = [
                        'us-east-1': '6671531875:AAG0nnI0XX_kneDgsOXNfclJi0V0tpuGwBU',
                        'ap-south-1': '7044416595:AAFDY6RAiufAjCvsot6L-rdaPh9CXiglO_U',
                        'eu-central-1': '7147432970:AAElUbz9aCKVVv7rIpPOfXS3sdjqaS6i4Lg',
                        'eu-west-1': '7188330154:AAHc8Vtm6iLZ9iWtQ_-z40OvYUb0qxZpc78',
                        'sa-east-1': '6485930075:AAEvoo4mqpG13fEZJLB0vW50eShyWIeV0gc'
                    ]
                    def token_zone = tokens[params.zonechoice]

                    sh 'ls -lart'  // List files to ensure region.tfvars exists
                    sh "terraform plan -var-file=\"region.tfvars\" -var 'region_aws=${params.zonechoice}' -var 'telegram_token=${token_zone}'"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.APPLY_TERRAFORM }
            }
            steps {
                script {
                    echo "=================Terraform Apply=================="
                    def tokens = [
                        'us-east-1': '6671531875:AAG0nnI0XX_kneDgsOXNfclJi0V0tpuGwBU',
                        'ap-south-1': '7044416595:AAFDY6RAiufAjCvsot6L-rdaPh9CXiglO_U',
                        'eu-central-1': '7147432970:AAElUbz9aCKVVv7rIpPOfXS3sdjqaS6i4Lg',
                        'eu-west-1': '7188330154:AAHc8Vtm6iLZ9iWtQ_-z40OvYUb0qxZpc78',
                        'sa-east-1': '6485930075:AAEvoo4mqpG13fEZJLB0vW50eShyWIeV0gc'
                    ]
                    def token_zone = tokens[params.zonechoice]

                    sh 'ls -lart'  // List files to ensure region.tfvars exists
                    sh "terraform apply -var-file=\"region.tfvars\" -var 'region_aws=${params.zonechoice}' -var 'telegram_token=${token_zone}' -auto-approve"

                    // Retrieve the Terraform output for public_ips
                    TERRAFORM_OUTPUT = sh(script: "terraform output -json public_ips", returnStdout: true).trim()
                }
            }
        }

        stage('Run Docker Containers on EC2 Instances') {
            when {
                expression { params.APPLY_TERRAFORM }
            }
            steps {
                script {
                    // Split the Terraform output to get public IPs
                    def publicIps = TERRAFORM_OUTPUT.split(',')
                    echo "Instance Public IPs: ${publicIps}"

                    // Define the SSH key path and user
                    def keyPath = "my-key-1.pem"
                    def user = 'ubuntu'
                    def dockerImages = ['playbot-ec2-one', 'playbot-ec2-two', 'yolo5-ec2']

                    // Iterate over each public IP and run Docker containers
                    publicIps.eachWithIndex { ip, index ->
                        def image = dockerImages[index]

                        sh """
                            echo ${ip}
                            ssh -o StrictHostKeyChecking=no -i ${keyPath} ${user}@${ip} << EOF
                            sudo docker pull ${DOCKER_HUB_REPO}/${image}:latest
                            sudo docker run -d --name ${image} -p 8443:8443 ${DOCKER_HUB_REPO}/${image}:latest
                            echo '[Unit]
                            Description=Start ${image} Docker container
                            Requires=docker.service
                            After=docker.service

                            [Service]
                            Restart=always
                            ExecStart=/usr/bin/docker start -a ${image}
                            ExecStop=/usr/bin/docker stop -t 2 ${image}

                            [Install]
                            WantedBy=multi-user.target' | sudo tee /etc/systemd/system/${image}.service
                            sudo systemctl enable ${image}.service
                            sudo systemctl start ${image}.service
                            EOF
                        """
                    }
                }
            }
        }



        stage('Terraform Destroy') {
            when {
                expression { params.DESTROY_TERRAFORM }
            }   
            steps {
                script {
                    echo "=================Terraform Destroy=================="
                    def tokens = [
                        'us-east-1': '6671531875:AAG0nnI0XX_kneDgsOXNfclJi0V0tpuGwBU',
                        'ap-south-1': '7044416595:AAFDY6RAiufAjCvsot6L-rdaPh9CXiglO_U',
                        'eu-central-1': '7147432970:AAElUbz9aCKVVv7rIpPOfXS3sdjqaS6i4Lg',
                        'eu-west-1': '7188330154:AAHc8Vtm6iLZ9iWtQ_-z40OvYUb0qxZpc78',
                        'sa-east-1': '6485930075:AAEvoo4mqpG13fEZJLB0vW50eShyWIeV0gc'
                    ]
                    def token_zone = tokens[params.zonechoice]

                    sh 'ls -lart'  // List files to ensure region.tfvars exists
                    sh "terraform destroy -var-file=\"region.tfvars\" -var 'region_aws=${params.zonechoice}' -var 'telegram_token=${token_zone}' -auto-approve"
                }
            }
        }

    }
}








