locals {
  azs                  = data.aws_availability_zones.available.names
  secret_id            = aws_db_instance.db.master_user_secret[0].secret_arn
  #lambda_function_name = split(":", aws_lambda_function.lambda.arn)[6]
}