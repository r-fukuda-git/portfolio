resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.env}-key"
  public_key = file("${var.key_path}")
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  subnet_id                   = var.subnet_id
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = var.security_groups
  count                       = var.ec2_instance_count

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "alias/aws/ebs"
    tags = {
      Name = "${var.project_name}-${var.env}-ebs"
    }
  }

  disable_api_termination = var.disable_api_termination
  iam_instance_profile    = var.iam_instance_profile
  monitoring              = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-ec2"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

output "ec2_instance_id" {
  value = aws_instance.ec2[*].id
}

output "ec2_public_ip" {
  value = aws_instance.ec2[*].public_ip
}

output "ec2_private_ip" {
  value = aws_instance.ec2[*].private_ip
}

output "ec2_ami_id" {
  value = aws_instance.ec2[*].ami
}