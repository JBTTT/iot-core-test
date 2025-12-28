resource "aws_ecs_cluster" "monitoring" {
  name = "${var.prefix}-${var.env}-monitoring"
}

resource "aws_security_group" "grafana" {
  name   = "${var.prefix}-${var.env}-grafana-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}