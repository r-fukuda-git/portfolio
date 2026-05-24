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

variable "skip_final_snapshot" {
  type        = bool
  description = "false の場合、削除時に final_snapshot_identifier でスナップショットを作成する"
  default     = false
}

variable "final_snapshot_identifier" {
  type        = string
  default     = null
  description = "skip_final_snapshot=false 時のスナップショット名。未指定時は {project}-{env}-rds-final"
}

variable "copy_tags_to_snapshot" {
  type    = bool
  default = true
}

variable "delete_automated_backups" {
  type        = bool
  default     = false
  description = "インスタンス削除時に自動バックアップも削除するか"
}

variable "master_user_secret_kms_key_id" {
  type        = string
  default     = null
  description = "RDS 管理シークレット用 KMS キー ID。null の場合は aws/secretsmanager を使用"
}

variable "rds_parameters" {
  type = map(string)
  default = {
    "character_set_server" = "utf8mb4"
    "slow_query_log"       = "1"
    "long_query_time"      = "2.0"
  }
}