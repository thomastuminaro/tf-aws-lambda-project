# roles VPC + invoke DB for Lambda + probably access secret manager secret

# Getting information about user calling the script
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "executedb" {
  name = "${var.common_tags.Project}-allow-lambda-db"
  path = "/"
  description = "Policy to allow Lambda function to execute actions on MySQL DB."

  policy = jsonencode({
    "Version": "2012-10-17",
	  "Statement": [
      {
        "Effect": "Allow",
        "Action": "rds-db:connect",
        "Resource": "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.common_tags.Project}-db/${aws_db_instance.db.username}"
      }
	]
  })
}