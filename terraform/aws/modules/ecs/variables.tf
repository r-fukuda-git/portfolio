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

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL from 03_ecr remote state (image URI base)"
}

variable "service_image_tag" {
  type        = string
  description = "Image tag in the ECR repository (CodeBuild pushes :latest)"
  default     = "latest"
}

variable "service_container_port" {
  type = number
}

variable "service_host_port" {
  type = number
}

variable "service_desired_count" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for the internet-facing ALB"
}

variable "security_group_ids" {
  type = list(string)
}

variable "alb_security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the ALB"
}

variable "vpc_id" {
  type = string
}

variable "health_check_path" {
  type        = string
  description = "ALB target group health check path"
  default     = "/"
}

variable "service_log_retention_in_days" {
  type        = number
  description = "CloudWatch Logs retention for the ECS service container"
  default     = 14
}

variable "service_task_cpu" {
  type    = number
  default = 256
}

variable "service_task_memory" {
  type    = number
  default = 512
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
