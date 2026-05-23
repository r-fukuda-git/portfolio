output "pipeline_name" {
  value = aws_codepipeline.this.name
}

output "pipeline_arn" {
  value = aws_codepipeline.this.arn
}

output "role_arn" {
  value = aws_iam_role.this.arn
}
