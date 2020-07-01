# Grab AWS Account ID
data "aws_caller_identity" "current" {}

# Create CodeCommit Repository for Storing Code
resource "aws_codecommit_repository" "sampleAppRepo" {
  repository_name = "sample-app"
  description     = "Sample Application Repository"
}

# ECR Repository for pushing Docker Container Images
resource "aws_ecr_repository" "terraria" {
  name                 = "terraria"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create CodeBuild Project for building the container image
resource "aws_codebuild_project" "sampleAppProject" {
  name          = "sample-app-project"
  description   = "Automated Build for Sample App using CodeBuild"
  build_timeout = "5"
  service_role  = aws_iam_role.eksAdminRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "terraria"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.logs.id}/codebuild"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.sampleAppRepo.clone_url_http
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "refs/heads/master"

  tags = {
    Environment = "Test"
  }
} 