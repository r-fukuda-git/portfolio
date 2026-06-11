variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ec2_instance_count" {
  type = number
}

variable "ec2_instance_type" {
  type = string
}

variable "key_path" {
  type = string
}

variable "disable_api_termination" {
  type = bool
}

variable "source_cidr_blocks" {
  type = list(string)
}

variable "target_cidr_blocks" {
  type = list(string)
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
