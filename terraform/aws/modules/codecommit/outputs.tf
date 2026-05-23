output "repository_name" {
  value = aws_codecommit_repository.this.repository_name
}

output "repository_arn" {
  value = aws_codecommit_repository.this.arn
}

output "clone_url_http" {
  value = aws_codecommit_repository.this.clone_url_http
}

output "clone_url_ssh" {
  value = aws_codecommit_repository.this.clone_url_ssh
}
