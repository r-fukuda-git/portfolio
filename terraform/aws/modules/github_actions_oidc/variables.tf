variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "main_deploy_branches" {
  type        = list(string)
  description = "GitHub branches allowed to assume the deploy role (refs/heads/<branch>)"
  default     = ["main"]
}

variable "ecr_repository_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}
