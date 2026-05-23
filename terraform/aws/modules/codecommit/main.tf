resource "aws_codecommit_repository" "this" {
  repository_name = "${var.project_name}-${var.env}-${var.repository_suffix}"
  description     = var.description

  tags = {
    Name = "${var.project_name}-${var.env}-${var.repository_suffix}"
  }
}
