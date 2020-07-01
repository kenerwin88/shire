#!/bin/bash
#pip3 install git-remote-codecommit
# # # Run Terraform, don't use backend because it isn't created yet
# # terraform init
# # terraform apply -auto-approve
# terraform init
# terraform apply -auto-approve

# # # Now rerun Terraform, with backend, reconfigure it automatically
# # mv backend.disabled backend.tf
# # terraform init -force-copy
# # terraform apply -auto-approve
# mv backend.disabled backend.tf
# terraform init -force-copy
# terraform apply -auto-approve

# # # Remove Localstate, it isn't used now
# # rm terraform.tfstate
# # rm terraform.tfstate.backup
# rm terraform.tfstate
# rm terraform.tfstate.backup

# Push this repository to Code Commit, we're building an example pipeline.
cd sampleApp
git init
git add .
git commit -m 'Initial Commit'
git push codecommit::us-east-1://sample-app --all --force
rm -Rf .git
cd .. 

cp kubeconfig_shire-cluster lambdas/config
sed -i "s/command: aws-iam-authenticator/command: .\/bin\/aws-iam-authenticator/g" lambdas/config
chmod a+rw ./lambdas/config
cd lambdas
zip -r kubectl.zip .
cd ..
