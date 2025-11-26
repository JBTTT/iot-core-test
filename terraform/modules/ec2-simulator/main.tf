#############################################
# EC2 SIMULATOR MODULE — cet11-grp1
#############################################

resource "aws_iam_role" "sim_role" {
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

resource "aws_iam_role_policy" "sim_policy" {
  name = "${var.prefix}-${var.env}-sim-policy"
  role = aws_iam_role.sim_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect: "Allow",
      Action: [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "sim_profile" {
  name = "${var.prefix}-${var.env}-sim-profile"
  role = aws_iam_role.sim_role.name
}

resource "aws_instance" "sim_ec2" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  iam_instance_profile   = aws_iam_instance_profile.sim_profile.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh", {
    prefix       = var.prefix
    env          = var.env
    iot_endpoint = var.iot_endpoint
  })

  tags = {
    Name = "${var.prefix}-${var.env}-iot-simulator"
  }
}

