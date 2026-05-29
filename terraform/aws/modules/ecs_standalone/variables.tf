variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type        = string
  description = "Task role (taskRoleArn) for application containers. Use null to omit."
  default     = null
}

variable "cluster_arn" {
  type        = string
  description = "ECS cluster ARN from 04_compute_ecs remote state"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name from 04_compute_ecs remote state"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL; used when standalone_image is empty"
  default     = ""
}

variable "service_image_tag" {
  type        = string
  description = "Image tag in ECR when standalone_image is empty"
  default     = "latest"
}

variable "standalone_image" {
  type        = string
  description = "Container image for standalone tasks; empty string reuses the ECR service image"
  default     = ""
}

variable "standalone_command" {
  type        = list(string)
  description = "Command override for the standalone container"
  default     = ["sh", "-c", "echo standalone task completed"]
}

variable "standalone_task_cpu" {
  type    = number
  default = 256
}

variable "standalone_task_memory" {
  type    = number
  default = 512
}

variable "standalone_schedule_enabled" {
  type        = bool
  description = "When true, EventBridge runs the standalone task on a schedule"
  default     = false
}

variable "standalone_schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (e.g. rate(1 day))"
  default     = "rate(1 day)"
}
