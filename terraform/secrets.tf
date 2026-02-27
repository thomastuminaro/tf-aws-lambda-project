# secret rds proxy / rds db instance 

data "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_db_instance.db.master_user_secret[0].secret_arn
} 