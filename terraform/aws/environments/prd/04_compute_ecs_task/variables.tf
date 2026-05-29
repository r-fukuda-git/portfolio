variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ecr_repository_suffix" {
  type        = string
  description = "03_ecr の repository_suffix と揃える"
  default     = "app"
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

variable "service_image_tag" {
  type        = string
  description = "ECR image tag when standalone_image is empty"
  default     = "latest"
}
