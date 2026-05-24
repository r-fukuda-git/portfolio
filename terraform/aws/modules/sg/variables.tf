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

variable "create_ecs_and_alb_security_groups" {
  type        = bool
  description = "Create ECS task and ALB security groups"
  default     = true
}