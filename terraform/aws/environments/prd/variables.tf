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

variable "cidr_block_vpc" {
  type = string
}

variable "source_cidr_blocks" {
  type = list(string)
}

variable "target_cidr_blocks" {
  type = list(string)
}

variable "public_subnet_1a" {
  type = string
}

variable "public_subnet_1c" {
  type = string
}

variable "private_subnet_1a" {
  type = string
}

variable "private_subnet_1c" {
  type = string
}

variable "route_cidr_block" {
  type = string
}

variable "key_path" {
  type = string
}

variable "disable_api_termination" {
  type = bool
}

variable "instance_class" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "multi_az" {
  type = bool
}

variable "deletion_protection" {
  type = bool
}

variable "backup_window" {
  type = string
}

variable "maintenance_window" {
  type = string
}

variable "backup_retention_period" {
  type = number
}