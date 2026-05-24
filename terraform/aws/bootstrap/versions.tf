terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42.0, < 7.0.0"
    }
  }

  # Bootstrap は初回のみ local。S3 作成後に各 stack を S3 backend へ移行する。
  backend "local" {
    path = "terraform.tfstate"
  }
}
