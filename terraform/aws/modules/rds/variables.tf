variable "project_name" {
  type = string
}

variable "env" {
  type = string
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

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "multi_az" {
  type = bool
}

variable "subnet_ids" {
  type = list(string)
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

variable "rds_parameters" {
  type = map(string)
  default = {
    "character_set_server" = "utf8mb4"
    "slow_query_log"       = "1"
    "long_query_time"      = "2.0"
  }
}