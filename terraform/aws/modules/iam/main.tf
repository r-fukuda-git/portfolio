# EC2用ロール
## 信頼関係構築
data "aws_iam_policy_document" "assumerole_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

## ロール作成
resource "aws_iam_role" "ssm" {
  name               = "${var.project_name}-${var.env}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ec2.json

  tags = {
    Name = "${var.project_name}-${var.env}-ec2-role"
  }
}

## ポリシー紐付け
resource "aws_iam_role_policy_attachment" "ssm_managed_role" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "rds_access" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

## インスタンスプロファイル作成
resource "aws_iam_instance_profile" "profile" {
  name = "${var.project_name}-${var.env}-profile"
  role = aws_iam_role.ssm.name
}

# ECS用ロール
## 信頼関係構築
data "aws_iam_policy_document" "assumerole_ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

## ロール作成
resource "aws_iam_role" "ecs" {
  name               = "${var.project_name}-${var.env}-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ecs.json

  tags = {
    Name = "${var.project_name}-${var.env}-ecs-role"
  }
}

## タスクロール作成（アプリケーション用）
## - 実行ロール(execution role)と責務を分けるために用意
## - 権限は利用側で必要に応じて付与する想定（ここでは最小構成）
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-${var.env}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ecs.json

  tags = {
    Name = "${var.project_name}-${var.env}-ecs-task-role"
  }
}

## ポリシー紐付け
resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
