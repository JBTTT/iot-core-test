output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "ec2_simulator_id" {
  value = module.ec2_simulator.instance_id
}

output "iot_certificate_arn" {
  value = module.iot.certificate_arn
}

output "dynamodb_table" {
  value = aws_dynamodb_table.db.name
}
