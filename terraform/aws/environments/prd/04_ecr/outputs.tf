output "ecr_repository_name" {
  description = "ECR repository name for CodeBuild push and ECS task image"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN for IAM policies"
  value       = module.ecr.repository_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL (docker login / image URI base)"
  value       = module.ecr.repository_url
}
