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
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db_proxy.id]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db"
  })
}

resource "aws_db_proxy" "proxy" {
  name                   = "${var.common_tags.Project}-proxy"
  debug_logging          = false
  engine_family          = "MYSQL"
  default_auth_scheme    = "NONE"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.proxy.arn
  vpc_security_group_ids = [aws_security_group.proxy_lambda.id]
  vpc_subnet_ids         = [for sub in aws_subnet.db : sub.id]

  auth {
    auth_scheme = "SECRETS"
    description = "Proxy authentication configuration."
    iam_auth    = "DISABLED"
    #username    = var.db_config.db_user
    secret_arn = local.secret_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db-proxy"
  })
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    init_query                   = "SET x=1, y=2"
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }

  lifecycle {
    replace_triggered_by = [ aws_db_proxy.proxy.id ]
  }
}

resource "aws_db_proxy_target" "db" {
  db_instance_identifier = aws_db_instance.db.identifier
  db_proxy_name =  aws_db_proxy.proxy.name
  target_group_name = aws_db_proxy_default_target_group.default.name

  lifecycle {
    replace_triggered_by = [ aws_db_proxy.proxy.id ]
  }
}