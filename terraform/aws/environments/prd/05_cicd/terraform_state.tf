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

locals {
  terraform_remote_state_base = {
    bucket = var.terraform_state_bucket
    region = var.terraform_state_region
  }

  terraform_state_key = {
    iam = "${var.terraform_state_key_prefix}/00_iam/terraform.tfstate"
    ecs = "${var.terraform_state_key_prefix}/03_compute_ecs/terraform.tfstate"
    ecr = "${var.terraform_state_key_prefix}/04_ecr/terraform.tfstate"
  }
}
