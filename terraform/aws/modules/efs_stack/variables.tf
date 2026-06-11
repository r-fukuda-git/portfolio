variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for mount targets (one per AZ)"
}

variable "client_security_group_ids" {
  type        = list(string)
  description = "Security groups in this stack that need NFS access to EFS"
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
