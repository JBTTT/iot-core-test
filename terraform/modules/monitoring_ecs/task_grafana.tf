resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.prefix}-${var.env}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "grafana/grafana:latest"
      portMappings = [{
        containerPort = 3000
      }]
      environment = [
        { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
        { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin" }
      ]
    }
  ])
}
