common_tags = {
  Admin     = "Thomas Tuminaro"
  Project   = "tf-aws-lambda-project"
  ManagedBy = "Terraform"
}

vpc_cidr = "10.0.0.0/16"

vpc_db_subnets = {
  "db-1" = {
    sub_cidr = "10.0.10.0/24"
  },
  "db-2" = {
    sub_cidr = "10.0.11.0/24"
  }
}

vpc_lambda_subnets = {
  "lambda-1" = {
    sub_cidr = "10.0.20.0/24"
  },
  "lambda-2" = {
    sub_cidr = "10.0.21.0/24"
  }
}

db_config = {
  db_class   = "db.t4g.micro"
  db_engine  = "mysql"
  db_storage = 10
  db_user    = "admin"
  db_name = "db_customers"
}