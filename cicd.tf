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
  service_role  = aws_iam_role.eks_service_role.arn

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

# CodePipeline
resource "aws_codepipeline" "codepipeline" {
  name     = "sample-app-pipeline"
  role_arn = aws_iam_role.codepipeline_service_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = "sample-app"
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildOutput"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.sampleAppProject.name
      }
    }
  }

  stage {
    name = "Deploy-Dev"

    action {
      name            = "Lambda"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["BuildOutput"]
      version         = "1"

      configuration = {
        FunctionName   = "helm"
        UserParameters = "namespace=dev,application=terraria"
      }
    }
  }

  stage {
    name = "Deploy-Stage"

    action {
      name            = "ApproveDeployToStage"
      category        = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      version         = "1"
      run_order        = "1"
    }

    action {
      name            = "Lambda"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["BuildOutput"]
      version         = "1"

      configuration = {
        FunctionName   = "helm"
        UserParameters = "namespace=stage,application=terraria"
      }
      run_order        = "2"
    }
  }

  stage {
    name = "Deploy-Prod"

    action {
      name            = "ApproveDeployToProd"
      category        = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      version         = "1"
      run_order        = "1"
    }

    action {
      name            = "Lambda"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["BuildOutput"]
      version         = "1"

      configuration = {
        FunctionName   = "helm"
        UserParameters = "namespace=prod,application=terraria"
      }
      run_order        = "2"
    }
  }
}
