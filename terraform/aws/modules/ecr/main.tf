resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-${var.env}-${var.repository_suffix}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = "${var.project_name}-${var.env}-${var.repository_suffix}"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}
