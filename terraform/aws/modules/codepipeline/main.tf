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
    sid    = "CodeCommitSource"
    effect = "Allow"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
    ]
    resources = [var.codecommit_repository_arn]
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

  statement {
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

  statement {
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

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json

  tags = {
    Name = "${local.name_prefix}-codepipeline-role"
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.name_prefix}-codepipeline-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_codepipeline" "this" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.this.arn

  artifact_store {
    location = var.artifact_bucket_name
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
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = var.codecommit_repository_name
        BranchName           = var.source_branch
        PollForSourceChanges = var.poll_for_source_changes
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
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  stage {
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

  tags = {
    Name = "${local.name_prefix}-pipeline"
  }
}

resource "aws_codestarnotifications_notification_rule" "pipeline" {
  count = var.enable_notifications && var.notification_target_arn != null ? 1 : 0

  name        = "${local.name_prefix}-pipeline-notifications"
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
    Name = "${local.name_prefix}-pipeline-notifications"
  }
}
