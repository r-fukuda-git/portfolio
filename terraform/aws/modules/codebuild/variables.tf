variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "project_suffix" {
  type        = string
  description = "CodeBuild project name suffix (e.g. dev-ci, main-cd)"
}

variable "description" {
  type    = string
  default = "CodeBuild project"
}

variable "artifact_bucket_arn" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_status_context" {
  type        = string
  description = "GitHub commit status context label"
  default     = "aws/codebuild"
}

variable "github_token_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for GitHub PAT (repo:status). Secret JSON: {\"token\":\"...\"}"
  default     = null
  nullable    = true
}

variable "ecr_repository_name" {
  type     = string
  default  = null
  nullable = true
}

variable "container_name" {
  type        = string
  description = "ECS task container name referenced in imagedefinitions.json"
  default     = null
  nullable    = true
}

variable "dockerfile_path" {
  type     = string
  default  = null
  nullable = true
}

variable "build_context" {
  type     = string
  default  = null
  nullable = true
}

variable "go_module_path" {
  type        = string
  description = "Path to Go module relative to repository root"
  default     = null
  nullable    = true
}

variable "enable_ecr_access" {
  type    = bool
  default = false
}

variable "privileged_mode" {
  type    = bool
  default = false
}

variable "buildspec" {
  type        = string
  description = "CodeBuild buildspec document"
}

variable "compute_type" {
  type    = string
  default = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "build_timeout" {
  type    = number
  default = 20
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}
