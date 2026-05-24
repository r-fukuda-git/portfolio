variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "source_cidr_blocks" {
  type = list(string)
}

variable "target_cidr_blocks" {
  type = list(string)
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

variable "skip_final_snapshot" {
  type = bool
}

variable "final_snapshot_identifier" {
  type    = string
  default = null
}

variable "copy_tags_to_snapshot" {
  type = bool
}

variable "delete_automated_backups" {
  type = bool
}
