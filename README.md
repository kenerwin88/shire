# shire
My Perfect Happy AWS Land (Someday)

## Requirements
aws-iam-authenticator
istioctl (https://istio.io)

## Setup
Please note, this does run Terraform twice.  The reason is because this repository is actually used to create the S3 and DynamoDB bucket for storing Terraform state and tracking locking.  We can't configure the backend properly though until AFTER they have been created.  After this initial step, you can use Terraform normally (one run == success).
```
terraform apply -auto-approve
mv backend.disabled backend.tf
terraform init -force-copy
terraform apply -auto-approve
```

istioctl install --set profile=demo

## Destroy

1. Delete the Istio generated load balancers!
2. Run this script
```bash
# Disable Backend State, Reconfigure, Nuke
mv backend.tf backend.disabled
terraform init -force-copy
terraform destroy -auto-approve
```