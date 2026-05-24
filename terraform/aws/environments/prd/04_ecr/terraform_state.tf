variable "terraform_state_bucket" {
  type        = string
  description = "S3 bucket for Terraform remote state"
}

variable "terraform_state_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS region of the state bucket"
}

variable "terraform_state_key_prefix" {
  type        = string
  description = "S3 key prefix (e.g. prd). Keys are {prefix}/{stack}/terraform.tfstate"
}
