#############################################
# ECR MODULE — SAFE & IDEMPOTENT
#############################################

locals {
  full_repo_name = "${var.prefix}-${var.env}-${var.repository_name}"
}

#############################################
# Lookup existing repository (if any)
#############################################

data "aws_ecr_repository" "existing" {
  name = local.full_repo_name
}

#############################################
# Create repository only if missing
#############################################

resource "aws_ecr_repository" "this" {
  count = length(try(data.aws_ecr_repository.existing.id, "")) == 0 ? 1 : 0

  name                 = local.full_repo_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = local.full_repo_name
    Environment = var.env
  }
}

#############################################
# Lifecycle policy (works for both cases)
#############################################

resource "aws_ecr_lifecycle_policy" "this" {
  repository = coalesce(
    try(aws_ecr_repository.this[0].name, null),
    data.aws_ecr_repository.existing.name
  )

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#############################################
# Output canonical repository URL
#############################################

output "repository_url" {
  value = coalesce(
    try(aws_ecr_repository.this[0].repository_url, null),
    data.aws_ecr_repository.existing.repository_url
  )
}
