data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.env}"
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*",
    ]
  }

  statement {
    sid    = "S3Artifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = var.enable_ecr_access ? [1] : []
    content {
      sid    = "ECRAccess"
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.github_token_secret_arn != null ? [1] : []
    content {
      sid    = "GitHubStatusSecret"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [var.github_token_secret_arn]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-${var.project_suffix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  tags = {
    Name = "${local.name_prefix}-${var.project_suffix}-codebuild-role"
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.name_prefix}-${var.project_suffix}-codebuild-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${local.name_prefix}-${var.project_suffix}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${local.name_prefix}-${var.project_suffix}-codebuild-logs"
  }
}

resource "aws_codebuild_project" "this" {
  name          = "${local.name_prefix}-${var.project_suffix}"
  description   = var.description
  service_role  = aws_iam_role.this.arn
  build_timeout = var.build_timeout

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = var.privileged_mode
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "GITHUB_OWNER"
      value = var.github_owner
    }

    environment_variable {
      name  = "GITHUB_REPOSITORY"
      value = var.github_repository
    }

    environment_variable {
      name  = "GITHUB_STATUS_CONTEXT"
      value = var.github_status_context
    }

    dynamic "environment_variable" {
      for_each = var.ecr_repository_name != null ? [1] : []
      content {
        name  = "IMAGE_REPO_NAME"
        value = var.ecr_repository_name
      }
    }

    dynamic "environment_variable" {
      for_each = var.container_name != null ? [1] : []
      content {
        name  = "CONTAINER_NAME"
        value = var.container_name
      }
    }

    dynamic "environment_variable" {
      for_each = var.dockerfile_path != null ? [1] : []
      content {
        name  = "DOCKERFILE_PATH"
        value = var.dockerfile_path
      }
    }

    dynamic "environment_variable" {
      for_each = var.build_context != null ? [1] : []
      content {
        name  = "BUILD_CONTEXT"
        value = var.build_context
      }
    }

    dynamic "environment_variable" {
      for_each = var.go_module_path != null ? [1] : []
      content {
        name  = "GO_MODULE_PATH"
        value = var.go_module_path
      }
    }

    dynamic "environment_variable" {
      for_each = var.github_token_secret_arn != null ? [1] : []
      content {
        name  = "GITHUB_TOKEN"
        type  = "SECRETS_MANAGER"
        value = "${var.github_token_secret_arn}:token::"
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }
  }

  tags = {
    Name = "${local.name_prefix}-${var.project_suffix}"
  }
}
