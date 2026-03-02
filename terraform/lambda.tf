# create function + upload zip + configure vpc + configure role

data "archive_file" "lambda" {
  type = "zip"
  source_file = "../src/main.py"
  output_path = "../src/function.zip"
}

resource "aws_lambda_function" "lambda" {
  filename = data.archive_file.lambda.output_path
  code_sha256 = data.archive_file.lambda.output_base64sha256
  function_name = "test"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.14"
  handler = "main.lambda_handler"

  vpc_config {
    subnet_ids         = [for sub in aws_subnet.lambda : sub.id]
    security_group_ids = [aws_security_group.lambda_proxy.id]
  }
}