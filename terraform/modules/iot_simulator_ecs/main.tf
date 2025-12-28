resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.prefix}-${var.env}-iot-simulator"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-${var.env}-iot-simulator"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "iot-simulator"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "ENV", value = var.env }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.prefix}-${var.env}-iot-simulator"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

network_configuration {
  subnets          = var.subnet_ids
  security_groups  = var.security_group_ids
  assign_public_ip = false
}

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}
