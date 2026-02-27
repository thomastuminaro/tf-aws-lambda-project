locals {
  azs = data.aws_availability_zones.available.names
  /* db_creds = {
        username = var.db_config.db_user
        password = data.aws_secretsmanager_random_password.random_password 
    } */
}