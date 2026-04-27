provider "aws" {
  region = "ap-northeast-1"
}

module "iam" {
  source       = "../../../modules/iam"
  env          = var.env
  project_name = var.project_name
}

output "iam_instance_profile" {
  value = module.iam.iam_instance_profile
}
