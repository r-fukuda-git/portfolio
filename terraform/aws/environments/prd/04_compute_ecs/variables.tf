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
  description = "ECR image tag for the ECS service (must exist in 03_ecr repository)"
  default     = "latest"
}

variable "service_container_port" {
  type = number
}

variable "service_desired_count" {
  type = number
}

variable "health_check_path" {
  type        = string
  description = "ALB target group health check path (cicd-demo: /health)"
  default     = "/health"
}

variable "efs_expected_storage_gb" {
  type    = number
  default = 100
}

variable "efs_performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "efs_throughput_mode" {
  type    = string
  default = "bursting"
}
