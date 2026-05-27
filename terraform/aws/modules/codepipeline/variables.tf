variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "pipeline_suffix" {
  type        = string
  description = "Pipeline name suffix (e.g. dev-ci, main-cd)"
}

variable "artifact_bucket_name" {
  type = string
}

variable "artifact_bucket_arn" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "source_branch" {
  type = string
}

variable "trigger_push_branches" {
  type        = list(string)
  description = "Branches that trigger pipeline on push"
  default     = []
}

variable "trigger_pull_request_branches" {
  type        = list(string)
  description = "Base branches that trigger pipeline on pull request open/update"
  default     = []
}

variable "codebuild_project_name" {
  type = string
}

variable "codebuild_project_arn" {
  type = string
}

variable "include_deploy_stage" {
  type    = bool
  default = false
}

variable "ecs_cluster_name" {
  type     = string
  default  = null
  nullable = true
}

variable "ecs_service_name" {
  type     = string
  default  = null
  nullable = true
}

variable "ecs_task_execution_role_arn" {
  type     = string
  default  = null
  nullable = true
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
