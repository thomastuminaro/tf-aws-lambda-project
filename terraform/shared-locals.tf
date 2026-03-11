locals {
  azs       = data.aws_availability_zones.available.names
  secret_id = aws_db_instance.db.master_user_secret[0].secret_arn
  #secret_name = element(split("/").aws_db_instance.db.master_user_secret[0].secret_arn, length(split("/").aws_db_instance.db.master_user_secret[0].secret_arn) - 1)
  #lambda_function_name = split(":", aws_lambda_function.lambda.arn)[6]
}