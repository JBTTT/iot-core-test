output "repository_url" {
  description = "ECR repository URL (existing or newly created)"
  value = coalesce(
    try(aws_ecr_repository.this[0].repository_url, null),
    data.aws_ecr_repository.existing.repository_url
  )
}

output "repository_name" {
  description = "ECR repository name (existing or newly created)"
  value = coalesce(
    try(aws_ecr_repository.this[0].name, null),
    data.aws_ecr_repository.existing.name
  )
}
