#!/bin/bash

# Disable S3 Backend
rm backend.tf
terraform init -force-copy

# Destroy World
terraform destroy -auto-approve
