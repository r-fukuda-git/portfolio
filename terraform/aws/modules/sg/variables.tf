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

variable "ecs_container_port" {
  type        = number
  description = "Container port exposed by ECS tasks behind the ALB"
  default     = 80
}