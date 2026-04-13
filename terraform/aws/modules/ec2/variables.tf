variable env {
  type = string
}

variable project_name {
  type = string
}

variable ec2_instance_count {
  type        = number
}

variable ec2_instance_type {
  type = string
}

variable subnet_id {
  type = string
}

variable security_groups {
  type = list(string)
}

variable iam_instance_profile {
  type = string
}

variable "key_path" {
  type = string
}