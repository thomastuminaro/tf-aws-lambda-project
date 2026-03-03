# roles VPC + invoke DB for Lambda + probably access secret manager secret ++++ ROLE FOR LAMBDA TO VPC ENDPOINT (not needed)

# Getting information about user calling the script
data "aws_caller_identity" "current" {}

# Policy for AWS Lambda role to access database
resource "aws_iam_policy" "executedb" {
  name        = "${var.common_tags.Project}-allow-lambda-db"
  path        = "/"
  description = "Policy to allow Lambda function to execute actions on MySQL DB."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "rds-db:connect",
        "Resource" : "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.common_tags.Project}-db/${aws_db_instance.db.username}"
      }
    ]
  })
}

# Policy for AWS Lambda role to write to CloudWatch
resource "aws_iam_policy" "writecloudwatch" {
  name        = "${var.common_tags.Project}-allow-lambda-cloudwatch"
  path        = "/"
  description = "Policy to allow Lambda function to write logs in CloudWatch."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}:*" ### TODO AND TO TEST 
        ]
      }
    ]
  })
}

# IAM role creation for the Lambda function 
resource "aws_iam_role" "lambda" {
  name = "${var.common_tags.Project}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = var.common_tags
}

# Adding policy to Lambda role, will need access DB, access secret manager, access CloudWatch ++ VPC executioner lambda
resource "aws_iam_role_policy_attachment" "lambda-db" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.executedb.arn
}

data "aws_iam_policy" "lambda-vpc" {
  name = "AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda-vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.aws_iam_policy.lambda-vpc.arn
}

resource "aws_iam_role_policy_attachment" "lambda-cloudwatch" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.writecloudwatch.arn
}

resource "aws_iam_policy" "proxy-secretmanager" {
  name        = "${var.common_tags.Project}-allow-proxy-secret"
  path        = "/"
  description = "Policy to allow RDS proxy to access credentials of DB stored in secret manager."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "${aws_db_instance.db.master_user_secret[0].secret_arn}"
      }
    ]
  })
}

resource "aws_iam_role" "proxy" {
  name = "${var.common_tags.Project}-proxy-secret"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "proxy-secret" {
  role       = aws_iam_role.proxy.name
  policy_arn = aws_iam_policy.proxy-secretmanager.arn
}