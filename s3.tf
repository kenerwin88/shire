# Bucket to store Logs
resource "aws_s3_bucket" "logs" {
  bucket = var.logs_s3_bucket
  acl    = "log-delivery-write"

  tags = {
    Name        = var.logs_s3_bucket
    Environment = "Prod"
    Purpose     = "All CloudTrail Logs"
  }

  # Keep logs hot for 30 days, cold after 60, purge after 1 year.
  lifecycle_rule {
    prefix  = "logs/"
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 365
    }
  }
  force_destroy = true
}

# Terraform State Bucket
resource "aws_s3_bucket" "terraform" {
  bucket = var.terraform_s3_bucket
  acl    = "private"

  tags = {
    Name    = var.terraform_s3_bucket
    Purpose = "Storing Terraform State"
  }

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "logs/terraform"
  }
  versioning {
    enabled = true
  }
  force_destroy = true
}

# CodePipeline Artifact Bucket
resource "aws_s3_bucket" "codepipeline" {
  bucket = var.codepipeline_s3_bucket
  acl    = "private"

  tags = {
    Name    = var.codepipeline_s3_bucket
    Purpose = "Artifact storage for CodePipeline"
  }

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "logs/codepipeline"
  }
  versioning {
    enabled = false
  }
  force_destroy = true
}
