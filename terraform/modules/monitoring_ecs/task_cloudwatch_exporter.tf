resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                   = "${var.prefix}-${var.env}-cw-exporter"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn = aws_iam_role.task_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = "cloudwatch-exporter"
      image = "quay.io/prometheus/cloudwatch-exporter:latest"
      portMappings = [{
        containerPort = 9106
      }]
      command = [
        "--config.file=/config/cloudwatch.yml"
      ]
    }
  ])
}
