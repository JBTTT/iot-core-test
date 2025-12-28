resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-${var.env}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.prefix}-${var.env}-ecs-cluster"
    Environment = var.env
  }
}
