# EC2用プロファイルの名前を出力
output "iam_instance_profile" {
  value = aws_iam_instance_profile.profile.name
}

# ECS用タスク実行ロールのARNを出力
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs.arn
}

# ECS用タスクロール（アプリケーション用）のARNを出力
output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}
