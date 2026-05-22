resource "aws_eip" "ec2" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.env}-eip"
  }
}

resource "aws_eip_association" "ec2" {
  instance_id   = var.instance_id
  allocation_id = aws_eip.ec2.id
}
