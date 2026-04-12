resource "aws_eip" "ec2" {
  instance_id = module.ec2.instance_id
  domain = "vpc"
  tags {
    Name = {var.project_name}-${var.env}-eip
  }
}

resource "aws_eip_association" "ec2-eip" {
  instance_id = module.ec2_instance_id
  allocation_id = aws_eip.ec2.id
}

output ec2_elastic_ip {
  value       = aws_eip.ec2.public_ip
}
