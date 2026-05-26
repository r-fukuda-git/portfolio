output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}

output "main_deploy_role_arn" {
  value = aws_iam_role.github_actions_main.arn
}

output "main_deploy_role_name" {
  value = aws_iam_role.github_actions_main.name
}
