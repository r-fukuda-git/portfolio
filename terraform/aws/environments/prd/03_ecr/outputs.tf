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

output "vpc_endpoint_security_group_id" {
  description = "Security group for ECS/ECR interface VPC endpoints"
  value       = module.vpc_endpoints_ecs.endpoint_security_group_id
}

output "vpc_interface_endpoint_ids" {
  description = "Interface VPC endpoint IDs for ECS/ECR (ecr.api, ecr.dkr, logs, ecs)"
  value       = module.vpc_endpoints_ecs.interface_endpoint_ids
}

output "vpc_s3_endpoint_id" {
  description = "S3 gateway VPC endpoint ID for ECR image layers"
  value       = module.vpc_endpoints_ecs.s3_endpoint_id
}
