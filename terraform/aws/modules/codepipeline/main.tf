locals {
  name_prefix = "${var.project_name}-${var.env}"
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid    = "S3Artifacts"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "CodeStarConnection"
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [var.codestar_connection_arn]
  }

  statement {
    sid    = "CodeBuildStart"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [var.codebuild_project_arn]
  }

  dynamic "statement" {
    for_each = var.include_deploy_stage ? [1] : []
    content {
      sid    = "ECSDeploy"
      effect = "Allow"
      actions = [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.include_deploy_stage ? [1] : []
    content {
      sid    = "PassExecutionRole"
      effect = "Allow"
      actions = [
        "iam:PassRole",
      ]
      resources = [var.ecs_task_execution_role_arn]
      condition {
        test     = "StringLike"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-${var.pipeline_suffix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json

  tags = {
    Name = "${local.name_prefix}-${var.pipeline_suffix}-codepipeline-role"
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.name_prefix}-${var.pipeline_suffix}-codepipeline-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_codepipeline" "this" {
  name          = "${local.name_prefix}-${var.pipeline_suffix}-pipeline"
  role_arn      = aws_iam_role.this.arn
  pipeline_type = "V2"

  artifact_store {
    location = var.artifact_bucket_name
    type     = "S3"
  }

  dynamic "trigger" {
    for_each = length(var.trigger_push_branches) > 0 || length(var.trigger_pull_request_branches) > 0 ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"

      git_configuration {
        source_action_name = "Source"

        dynamic "push" {
          for_each = length(var.trigger_push_branches) > 0 ? [1] : []
          content {
            branches {
              includes = var.trigger_push_branches
            }
          }
        }

        dynamic "pull_request" {
          for_each = length(var.trigger_pull_request_branches) > 0 ? [1] : []
          content {
            events = ["OPEN", "UPDATED"]
            branches {
              includes = var.trigger_pull_request_branches
            }
          }
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repository}"
        BranchName       = var.source_branch
        DetectChanges    = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      output_artifacts = var.include_deploy_stage ? ["build_output"] : null

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.include_deploy_stage ? [1] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = {
          ClusterName = var.ecs_cluster_name
          ServiceName = var.ecs_service_name
          FileName    = "imagedefinitions.json"
        }
      }
    }
  }

  tags = {
    Name = "${local.name_prefix}-${var.pipeline_suffix}-pipeline"
  }
}

resource "aws_codestarnotifications_notification_rule" "pipeline" {
  count = var.enable_notifications && var.notification_target_arn != null ? 1 : 0

  name        = "${local.name_prefix}-${var.pipeline_suffix}-pipeline-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.this.arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
  ]

  target {
    address = var.notification_target_arn
    type    = var.notification_target_type
  }

  tags = {
    Name = "${local.name_prefix}-${var.pipeline_suffix}-pipeline-notifications"
  }
}
