variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type        = string
  description = "ECR repository name suffix (e.g. app -> {project}-{env}-app)"
  default     = "app"
}

variable "ecr_scan_on_push" {
  type    = bool
  default = true
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "lifecycle_policy" {
  type        = string
  description = "JSON lifecycle policy document; null disables lifecycle policy"
  default     = null
  nullable    = true
}
