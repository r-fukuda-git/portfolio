variable "project_name" {
  type        = string
  description = "State bucket / lock table name prefix"
}

variable "aws_region" {
  type        = string
  description = "AWS region for state bucket and DynamoDB lock table"
}
