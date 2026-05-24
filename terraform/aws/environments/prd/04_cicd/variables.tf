variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type        = string
  description = "CodeCommit repository name suffix (ECR suffix is managed in 04_ecr; keep values aligned)"
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
