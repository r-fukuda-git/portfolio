variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "instance_id" {
  type        = string
  description = "EC2 instance ID to associate with the Elastic IP"
}
