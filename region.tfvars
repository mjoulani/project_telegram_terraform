#                regoin.tfvars
#region_aws = "us-east-1"
#region_aws = "ap-south-1"
#region_aws = "eu-central-1"
#region_aws = "eu-west-1"
#region_aws = "sa-east-1"
region_aws = ""

#telegram_token = "hjfshjfdsfjhdksfd31564gdfg"
telegram_token = ""
telegram_url = "muhbot.click"

/*****************************vpc**********************/

vpc_name = "muh_telegram_bot"
vpc_cidr = "10.0.0.0/16"

/***********************public subnet*****************/

cidr_public_subnet   = ["10.0.0.0/24", "10.0.1.0/24"]

/*********************security group*******************/
ports = [22,80,8443,443]
types = ["ssh", "http", "Custom TCP", "https" ]

# terraform plan -var-file="region.tfvars" -var 'region_aws="us-east-1"' -var 'telegram_token="muhamedtoken1"'

# terraform apply -var-file="region.tfvars" -var 'region_aws="us-east-1"' -var 'telegram_token="muhamedtoken1"'

# terraform destroy -var-file="region.tfvars" -var 'region_aws="us-east-1"' -var 'telegram_token="muhamedtoken1"'






