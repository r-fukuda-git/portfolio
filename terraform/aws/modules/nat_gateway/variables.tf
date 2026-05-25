variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_route_table_id" {
  type = string
}

variable "route_cidr_block" {
  type = string
}

variable "availability_zone_suffix" {
  type        = string
  description = "Tag suffix for NAT (e.g. 1a)"
  default     = "1a"
}
