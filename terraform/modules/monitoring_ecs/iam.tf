#############################################
# Monitoring ECS IAM — SAFE & IDEMPOTENT
#############################################

data "aws_caller_identity" "current" {}

#############################################
# Lookup existing ECS task role
#############################################

data "aws_iam_role" "task_role" {
  name = var.task_role_name
}

#############################################
# Lookup existing CloudWatch read policy
#############################################

data "aws_iam_policy" "cw_read" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.cw_read_policy_name}"
}

#############################################
# Attach policy to task role (safe)
#############################################

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = data.aws_iam_role.task_role.name
  policy_arn = data.aws_iam_policy.cw_read.arn
}
