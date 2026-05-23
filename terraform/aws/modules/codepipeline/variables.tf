variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "artifact_bucket_name" {
  type = string
}

variable "artifact_bucket_arn" {
  type = string
}

variable "codecommit_repository_name" {
  type = string
}

variable "codecommit_repository_arn" {
  type = string
}

variable "source_branch" {
  type    = string
  default = "main"
}

variable "poll_for_source_changes" {
  type    = bool
  default = true
}

variable "codebuild_project_name" {
  type = string
}

variable "codebuild_project_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "enable_notifications" {
  type    = bool
  default = false
}

variable "notification_target_arn" {
  type        = string
  description = "SNS topic ARN or Chatbot configuration ARN"
  default     = null
}

variable "notification_target_type" {
  type    = string
  default = "SNS"
}
