variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "source_cidr_blocks" {
  type = list(string)
}

variable "target_cidr_blocks" {
  type = list(string)
}

variable "service_image_tag" {
  type        = string
  description = "ECR image tag for the ECS service (must exist in 04_ecr repository)"
  default     = "latest"
}

variable "service_container_port" {
  type = number
}

variable "service_desired_count" {
  type = number
}

variable "standalone_image" {
  type    = string
  default = ""
}

variable "standalone_command" {
  type    = list(string)
  default = ["sh", "-c", "echo standalone task completed"]
}

variable "standalone_schedule_enabled" {
  type    = bool
  default = false
}

variable "standalone_schedule_expression" {
  type    = string
  default = "rate(1 day)"
}
