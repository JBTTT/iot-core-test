output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "sg_id" {
  value = aws_security_group.main_sg.id
}
