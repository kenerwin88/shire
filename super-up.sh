#!/bin/bash

# Housekeeping
echo '😀 Welcome!  This will bring up a full demo EKS environment with CI/CD on AWS!'
echo -e  "⚙️ First, we need to configure some variables up front.  If you want to change them later on, just edit the demo.tfvars file!\n"
read -p '❓ What would you like to name your demo environment [shire]: ' environmentName
environmentName=${environmentName:-shire}

# Terraform S3 Check
TERRAFORM_BUCKET_NAME="$environmentName-terraform"
echo -e "\n💭 Ok, we need an S3 bucket to store Terraform state in, lets see if $BUCKET_NAME is available..."
echo "💭 Checking S3 bucket exists..."                                                                                                                                                                                                           

TERRAFORM_BUCKET_EXISTS=true                                                                                                                                                                                                                            
while $TERRAFORM_BUCKET_EXISTS; do
  S3_CHECK=$(aws s3 ls "s3://${TERRAFORM_BUCKET_NAME}" 2>&1)                                                                                                                                                 
  if [ $? != 0 ]
    then
    NO_BUCKET_CHECK=$(echo $S3_CHECK | grep -c 'NoSuchBucket')
    if [ $NO_BUCKET_CHECK = 1 ]; then
      echo "😄 $TERRAFORM_BUCKET_NAME Bucket does not exist, we'll use it!"
      TERRAFORM_BUCKET_EXISTS=false
    else 
      echo "😥 Error checking S3 Bucket, someone must have taken it or you don't have the aws cli tools installed!"
      SUFFIX=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)    
      TERRAFORM_BUCKET_NAME="$environmentName-$SUFFIX-terraform"
      echo "😥 Sorry but we're going to try $TERRAFORM_BUCKET_NAME out instead..."
    fi 
  fi
done

# Logs S3 Check
LOGS_BUCKET_NAME="$environmentName-logs"
echo -e "\n💭 Ok, we need an S3 bucket to store logs in, lets see if $LOGS_BUCKET_NAME is available..."
echo "💭 Checking S3 bucket exists..."                                                                                                                                                                                                           

LOGS_BUCKET_EXISTS=true                                                                                                                                                                                                                            
while $LOGS_BUCKET_EXISTS; do
  S3_CHECK=$(aws s3 ls "s3://${LOGS_BUCKET_NAME}" 2>&1)                                                                                                                                                 
  if [ $? != 0 ]
    then
    NO_BUCKET_CHECK=$(echo $S3_CHECK | grep -c 'NoSuchBucket')
    if [ $NO_BUCKET_CHECK = 1 ]; then
      echo "😄 $LOGS_BUCKET_NAME Bucket does not exist, we'll use it!"
      LOGS_BUCKET_EXISTS=false
    else 
      echo "😥 Error checking S3 Bucket, someone must have taken it or you don't have the aws cli tools installed!"
      SUFFIX=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)    
      LOGS_BUCKET_NAME="$environmentName-$SUFFIX-logs"
      echo "😥 Sorry but we're going to try $LOGS_BUCKET_NAME out instead..."
    fi 
  fi
done

# Save Settings
echo -e "\n😀 Looks like we are good to go, saving settings to terraform.tfvars."
echo "name = \"$environmentName\"" > terraform.tfvars
echo "terraform_s3_bucket = \"$TERRAFORM_BUCKET_NAME\"" >> terraform.tfvars
echo "logs_s3_bucket = \"$LOGS_BUCKET_NAME"\" >> terraform.tfvars

# Create Backend Buckets and DynamoDB
echo ""
while true; do
    read -p "😆 Ok, we're ready, are you ok if we run Terraform now? (y or n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "👍 Confirmed!  First up, let's bring up JUST the S3 buckets and DynamoDB for Terraform, we need them to store the Terraform state."
echo -e "\n📝 More information here https://www.terraform.io/docs/backends/types/s3.html"
echo "📝 TLDR, Terraform has a backend state, that tracks everything that it has created.  We want to store it in S3, that way if other"
echo "📝 people run Terraform, they'll all have the same version.  The DynamoDB table is used by Terraform to determine if someone else"
echo "📝 is already running Terraform, if they are, it will have a 'lock', and will prevent them from stepping on each other."

echo -e "\n😀 Ok we're going to run Terraform now!  Two S3 buckets and one DynamoDB table coming right up!"
terraform init
terraform apply -auto-approve -target=aws_s3_bucket.logs -compact-warnings
terraform apply -auto-approve -target=aws_s3_bucket.terraform -compact-warnings
terraform apply -auto-approve -target=aws_dynamodb_table.terraform_state_lock -compact-warnings
echo "✔ Success!  Now we're ready to set up the Terraform backend, let me do that for you by creating backend.tf real quick..."

# Configure the backend
cat >backend.tf <<EOL
terraform {
  backend "s3" {
    bucket         = "${TERRAFORM_BUCKET_NAME}"
    key            = "terraform"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
EOL
echo '---------- backend.tf -------------'
cat backend.tf
echo '-----------------------------------'
echo -e "\n💭 So, you probably noticed the bucket had to be hardcoded for the backend..."
echo -e "💭 Sadly it does, There is no way to pass that in properly as Terraform loads the variables AFTER the backend. \n"

# Switch to S3 Backend
echo "😀 Ok!  Let's re-initialize Terraform, and import our terraform.tfstate files into S3!"
terraform init -force-copy

# Create... Everything
echo -e "\n✔ Success!  Now, it's time... We are going to do a full terraform apply.  Go away and come back in 15 minutes to an EKS cluster and a bunch of other good things!"
terraform apply -auto-approve
