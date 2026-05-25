variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "route_cidr_block" {
  type = string
}

variable "availability_zone_suffix" {
  type        = string
  description = "NAT タグ用 AZ サフィックス（public 1a 配置時は 1a）"
  default     = "1a"
}
