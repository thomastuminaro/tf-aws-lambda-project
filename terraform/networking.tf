# VPC - subnets - security groups - ENI - VPC endpoint 

# Creating main VPC resource 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-vpc"
  })
}

# Grabbing available AZs to distribute traffic across AZs
data "aws_availability_zones" "available" {
    state = "available"
}

# Creating subnets 
resource "aws_subnet" "db" {
  for_each   = var.vpc_db_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.sub_cidr
  availability_zone = local.azs[ index([ for sub in keys(var.vpc_db_subnets) : sub ], each.key) % length(local.azs)]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-${each.key}"
  })
}

resource "aws_subnet" "lambda" {
  for_each   = var.vpc_lambda_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.sub_cidr
  availability_zone = local.azs[ index([ for sub in keys(var.vpc_lambda_subnets) : sub ], each.key) % length(local.azs)]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-${each.key}"
  })
}

# Creating required security group and rule for Lambda  

resource "aws_security_group" "lambda_proxy" {
  name = "${var.common_tags.Project}-lambda-proxy"
  description = "Security group to manage connections between Lambda function and RDS proxy."
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-lambda-proxy"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_sql_from_lambda_to_proxy" {
  security_group_id = aws_security_group.lambda_proxy.id
  referenced_security_group_id = aws_security_group.proxy_lambda.id
  from_port = 3306
  to_port = 3306
  ip_protocol = "tcp"
}

# Creating required security group and rule for RDS proxy   

resource "aws_security_group" "proxy_lambda" {
  name = "${var.common_tags.Project}-proxy-lambda"
  description = "Security group to manage connections of RDS proxy, to Lambda and RDS db."
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-proxy-lambda"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_sql_from_proxy_to_db" {
  security_group_id = aws_security_group.proxy_lambda.id
  referenced_security_group_id = aws_security_group.db_proxy.id
  from_port = 3306
  to_port = 3306
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_sql_from_lambda_to_proxy" {
  security_group_id = aws_security_group.proxy_lambda.id
  referenced_security_group_id = aws_security_group.lambda_proxy.id
  from_port = 3306
  to_port = 3306
  ip_protocol = "tcp"
}

# Creating required security group and rule for RDS DB   

resource "aws_security_group" "db_proxy" {
  name = "${var.common_tags.Project}-db-proxy"
  description = "Security group to manage connections on RDS DB, only to allow the connections from RDS proxy."
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-db-proxy"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_sql_from_proxy_to_db" {
  security_group_id = aws_security_group.db_proxy.id
  referenced_security_group_id = aws_security_group.proxy_lambda.id
  from_port = 3306
  to_port = 3306
  ip_protocol = "tcp"
}