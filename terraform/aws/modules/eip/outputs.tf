output "elastic_ip" {
  value = aws_eip.ec2.public_ip
}

output "allocation_id" {
  value = aws_eip.ec2.id
}
