variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
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

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "standalone_image" {
  type        = string
  description = "Container image for standalone tasks; empty string reuses var.image"
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

variable "enable_standalone_schedule" {
  type        = bool
  description = "When true, EventBridge runs the standalone task on a schedule"
  default     = false
}

variable "standalone_schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (e.g. rate(1 day))"
  default     = "rate(1 day)"
}
