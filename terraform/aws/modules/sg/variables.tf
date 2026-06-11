variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "source_cidr_blocks" {
  type = list(string)
}

variable "target_cidr_blocks" {
  type = list(string)
}

variable "container_port" {
  type        = number
  description = "Container port exposed by ECS tasks behind the ALB"
  default     = 80
}

variable "create_web_and_db_security_groups" {
  type        = bool
  description = "Create web (public) and db (private) security groups for EC2/RDS"
  default     = true
}

variable "create_web_security_group" {
  type        = bool
  description = "Create web (public) security group only"
  default     = false
}

variable "create_db_security_group" {
  type        = bool
  description = "Create db (private) security group only"
  default     = false
}

variable "db_ingress_source_security_group_id" {
  type        = string
  default     = null
  description = "Source SG for MySQL ingress on db SG when web SG is not created in this module"
}

variable "create_ecs_and_alb_security_groups" {
  type        = bool
  description = "Create ECS task and ALB security groups"
  default     = true
}