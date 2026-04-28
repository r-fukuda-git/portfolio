variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "image" {
  type = string
}

variable "containerPort" {
  type = number
}

variable "hostPort" {
  type = number
}

variable "desired_count" {
  type = number
}
