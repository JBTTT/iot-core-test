resource "aws_iam_role" "simulator_role" {
  name = "${var.prefix}-${var.env}-sim-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "simulator_policy" {
  name = "${var.prefix}-${var.env}-sim-policy"
  role = aws_iam_role.simulator_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "simulator_profile" {
  name = "${var.prefix}-${var.env}-sim-profile"
  role = aws_iam_role.simulator_role.name
}

resource "aws_instance" "simulator" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.simulator_profile.name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]

  user_data = templatefile("${path.module}/user_data.sh", {
    iot_endpoint   = var.iot_endpoint
    prefix         = var.prefix
    env            = var.env
  })

  tags = {
    Name = "${var.prefix}-${var.env}-iot-simulator"
  }
}
