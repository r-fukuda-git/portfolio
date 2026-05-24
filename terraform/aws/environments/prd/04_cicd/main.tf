data "aws_caller_identity" "current" {}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.iam
  })
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecs
  })
}

locals {
  name_prefix    = "${var.project_name}-${var.env}"
  container_name = "${var.project_name}-${var.env}-service-container"
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${local.name_prefix}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${local.name_prefix}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

module "codecommit" {
  source = "../../../modules/codecommit"

  env             = var.env
  project_name    = var.project_name
  repository_suffix = var.repository_suffix
  description     = var.codecommit_description
}

module "ecr" {
  source = "../../../modules/ecr"

  env              = var.env
  project_name     = var.project_name
  repository_suffix = var.repository_suffix
  scan_on_push     = var.ecr_scan_on_push
}

module "codebuild" {
  source = "../../../modules/codebuild"

  env          = var.env
  project_name = var.project_name

  artifact_bucket_arn = aws_s3_bucket.pipeline_artifacts.arn
  ecr_repository_name = module.ecr.repository_name
  container_name      = local.container_name
  dockerfile_path     = var.dockerfile_path
  build_context       = var.build_context
  compute_type        = var.codebuild_compute_type
  build_image         = var.codebuild_image
  build_timeout       = var.codebuild_timeout
}

module "codepipeline" {
  source = "../../../modules/codepipeline"

  env          = var.env
  project_name = var.project_name

  artifact_bucket_name = aws_s3_bucket.pipeline_artifacts.bucket
  artifact_bucket_arn  = aws_s3_bucket.pipeline_artifacts.arn

  codecommit_repository_name = module.codecommit.repository_name
  codecommit_repository_arn  = module.codecommit.repository_arn
  source_branch              = var.source_branch
  poll_for_source_changes    = var.poll_for_source_changes

  codebuild_project_name = module.codebuild.project_name
  codebuild_project_arn  = module.codebuild.project_arn

  ecs_cluster_name            = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  ecs_service_name            = data.terraform_remote_state.ecs.outputs.ecs_service_name
  ecs_task_execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn

  enable_notifications      = var.enable_pipeline_notifications
  notification_target_arn   = var.notification_target_arn
  notification_target_type  = var.notification_target_type
}
