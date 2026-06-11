variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "expected_storage_gb" {
  type    = number
  default = 100
}

variable "performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "throughput_mode" {
  type    = string
  default = "bursting"
}
