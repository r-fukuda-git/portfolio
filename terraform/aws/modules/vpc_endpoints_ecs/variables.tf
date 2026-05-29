variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for interface VPC endpoints"
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "Private route tables for S3 gateway endpoint"
}
