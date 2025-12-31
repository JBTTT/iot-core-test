#############################################
# Monitoring ECS IAM — ROLE OWNED BY MODULE
#############################################

data "aws_caller_identity" "current" {}

#############################################
# Assume role policy for ECS tasks
#############################################

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#############################################
# Create ECS task role (once, protected)
#############################################

resource "aws_iam_role" "task_role" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  lifecycle {
    prevent_destroy = true
  }
}

#############################################
# Lookup existing CloudWatch read policy
#############################################

data "aws_iam_policy" "cw_read" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.cw_read_policy_name}"
}

#############################################
# Attach policy to task role
#############################################

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = data.aws_iam_policy.cw_read.arn
}
