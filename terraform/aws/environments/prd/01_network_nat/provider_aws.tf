provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}
