# 信頼関係構築
data "aws_iam_policy_document" "assumerole_ec2" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

# ロール作成
resource "aws_iam_role" "ssm" {
    name = "${var.project_name}-${var.env}-ssm-role"
    assume_role_policy = data.aws_iam_policy_document.assumerole_ec2.json

    tags {
        Name = "${var.project_name}-${var.env}-ssm-role"
    }
}

# ポリシー紐付け
resource "aws_iam_role_policy_attachment" "ssm_managed_role" {
    role = aws_iam_role.ssm
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# インスタンスプロファイル作成
resource "aws_iam_instance_profile" "profile" {
    name = "${var.project_name}-${var.env}-profile"
    role = aws_iam_role.ssm
}