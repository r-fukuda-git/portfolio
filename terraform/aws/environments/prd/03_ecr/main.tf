module "ecr" {
  source = "../../../modules/ecr"

  env                  = var.env
  project_name         = var.project_name
  repository_suffix    = var.repository_suffix
  scan_on_push         = var.ecr_scan_on_push
  image_tag_mutability = var.image_tag_mutability
  lifecycle_policy     = var.lifecycle_policy
}
