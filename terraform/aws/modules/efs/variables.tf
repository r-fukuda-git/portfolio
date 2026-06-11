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
  description = "Private subnet IDs for mount targets (one per AZ)"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to mount the file system (NFS 2049)"
}

variable "expected_storage_gb" {
  type        = number
  description = "Expected capacity for cost/planning tags; EFS grows elastically"
  default     = 100
}

variable "performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "throughput_mode" {
  type    = string
  default = "bursting"
}

variable "encrypted" {
  type    = bool
  default = true
}
