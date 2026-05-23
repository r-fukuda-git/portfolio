variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type        = string
  description = "Suffix shared by CodeCommit and ECR repository names"
  default     = "app"
}

variable "codecommit_description" {
  type    = string
  default = "Application source repository for ECS deployment"
}

variable "source_branch" {
  type    = string
  default = "main"
}

variable "poll_for_source_changes" {
  type    = bool
  default = true
}

variable "dockerfile_path" {
  type    = string
  default = "Dockerfile"
}

variable "build_context" {
  type    = string
  default = "."
}

variable "codebuild_compute_type" {
  type    = string
  default = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "codebuild_timeout" {
  type    = number
  default = 20
}

variable "ecr_scan_on_push" {
  type    = bool
  default = true
}

variable "enable_pipeline_notifications" {
  type    = bool
  default = false
}

variable "notification_target_arn" {
  type    = string
  default = null
  nullable = true
}

variable "notification_target_type" {
  type    = string
  default = "SNS"
}
