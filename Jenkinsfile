pipeline {
    agent any

    environment {
        TF_VAR_zone = "${params.zonechoice}"
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub')
        DOCKER_HUB_REPO = 'mjoulani'
        GIT_REPO_URL = 'https://github.com/mjoulani/project_telegram_terraform.git'
    }

    parameters {
        choice choices: ['us-west-1', 'eu-west-1', 'eu-west-2', 'sa-east-1'], description: 'Choice Zone', name: 'zonechoice'
        booleanParam(name: 'Init_TERRAFORM', defaultValue: false, description: 'Check to init Terraform changes')
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to destroy Terraform-managed infrastructure')
    }

    stages {
        stage('Clone Repository') {
            steps {
                deleteDir() // Clean the workspace before cloning
                bat "dir" // List files to verify clean workspace (Windows equivalent of `ls -lart`)
                // Clone repository
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[url: "${GIT_REPO_URL}"]]
                ]
                bat "dir" // List files to verify clone (Windows equivalent of `ls -lart`)
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def dockerfilePath = 'project_telegram_terraform/playbot/ec2_one/Dockerfile'
                    def imageName = 'playbot-ec2-one'
                    def imageTag = "${DOCKER_HUB_REPO}/${imageName}:latest"
                    
                    // Build Docker image
                    bat "docker build -t ${imageTag} -f ${dockerfilePath} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', "${DOCKER_HUB_CREDENTIALS}") {
                        def imageName = 'playbot-ec2-one'
                        def imageTag = "${DOCKER_HUB_REPO}/${imageName}:latest"
                        
                        // Push Docker image
                        bat "docker push ${imageTag}"
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
                    dir('jenkins_terrform_project') { // Navigate to the directory containing main.tf
                        bat "terraform init -var 'zone=${params.zonechoice}'"
                    }
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
                    dir('jenkins_terrform_project') { 
                        bat "terraform plan -var 'zone=${params.zonechoice}'"
                    }
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
                    dir('jenkins_terrform_project') { 
                        bat "terraform apply -var 'zone=${params.zonechoice}' -auto-approve"
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
                    dir('jenkins_terrform_project') { 
                        bat "terraform destroy -auto-approve"
                    }
                }
            }
        }
    }
}
