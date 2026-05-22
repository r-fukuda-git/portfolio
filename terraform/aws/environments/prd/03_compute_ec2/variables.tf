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

variable "use_database_security_groups" {
  type        = bool
  description = "true の場合、02_database で作成済みの SG を利用し、本スタックでは SG を作成しない"
  default     = true
}
