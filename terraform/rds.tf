# rds db + rds db config + rds proxy 

resource "aws_db_subnet_group" "db" {
  name       = "${var.common_tags.Project}-db-subnets"
  subnet_ids = [for sub in aws_subnet.db : sub.id]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db-subnets"
  })
}

resource "aws_db_instance" "db" {
  db_name                     = var.db_config.db_name
  instance_class              = var.db_config.db_class
  allocated_storage           = var.db_config.db_storage
  engine                      = var.db_config.db_engine
  skip_final_snapshot         = true
  username                    = var.db_config.db_user
  manage_master_user_password = true
  db_subnet_group_name = aws_db_subnet_group.db.name
  vpc_security_group_ids = [ aws_security_group.db_proxy.id ]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db-subnets"
  })
}

resource "aws_db_proxy" "proxy" {
  name = "${var.common_tags.Project}-proxy"
  debug_logging = false
  engine_family = "MYSQL"
  idle_client_timeout = 1800
  require_tls = false
  role_arn = "" # TODO
  vpc_security_group_ids = [ aws_security_group.proxy_lambda ]
  vpc_subnet_ids = [ for sub in aws_subnet.db : sub.id ]

  auth {
    auth_scheme = "SECRETS"
    description = "Proxy authentication configuration."
    iam_auth = "REQUIRED"
    username = var.db_config.db_user
    secret_arn = local.secret_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db-proxy"
  })
}

