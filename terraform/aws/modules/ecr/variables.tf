variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type    = string
  default = "app"
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "lifecycle_policy" {
  type        = string
  description = "JSON lifecycle policy document; null disables lifecycle policy"
  default     = null
}
