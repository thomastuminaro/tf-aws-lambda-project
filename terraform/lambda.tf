# create function + upload zip + configure vpc + configure role

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "../src/" 
  output_path = "../src/function.zip"
}

resource "aws_lambda_function" "lambda" { # ADD LOGGING
  filename      = data.archive_file.lambda.output_path
  code_sha256   = data.archive_file.lambda.output_base64sha256
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.14"
  handler       = "main.lambda_handler"

  vpc_config {
    subnet_ids         = [for sub in aws_subnet.lambda : sub.id]
    security_group_ids = [aws_security_group.lambda_proxy.id]
  }

  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    system_log_level      = "INFO"
  }

  environment {
    variables = {
      proxy_endpoint = "${aws_db_proxy.proxy.endpoint}"
      db_user = "${var.db_config.db_user}"
      db_name = "${var.db_config.db_name}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}