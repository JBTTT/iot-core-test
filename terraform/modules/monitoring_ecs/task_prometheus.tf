resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.prefix}-${var.env}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "prometheus"
      image = "prom/prometheus:latest"
      portMappings = [{
        containerPort = 9090
      }]
    }
  ])
}
