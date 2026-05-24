output "state_bucket_name" {
  description = "Terraform remote state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_lock_table_name" {
  description = "Terraform state lock DynamoDB table"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "aws_region" {
  description = "Region used for remote state"
  value       = var.aws_region
}

output "state_key_prefix" {
  description = "S3 key prefix for environment stacks (e.g. prd/00_iam/terraform.tfstate)"
  value       = "prd"
}
