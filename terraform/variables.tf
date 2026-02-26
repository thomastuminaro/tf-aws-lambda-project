# COMMON VARS 

variable "common_tags" {
  type = object({
    Project   = string
    ManagedBy = string
    Admin     = string
  })
}

# NETWORKING VARS

variable "vpc_cidr" {
  type = string

  validation {
    condition = can(cidrnetmask(var.vpc_cidr))
    error_message = "Please enter a valid VPC cidr."
  }
}

variable "vpc_db_subnets" {
  type = map(object({
    sub_cidr = string
  }))

  validation {
    condition = alltrue([ for cidr in var.vpc_db_subnets : can(cidrnetmask(cidr.sub_cidr)) ])
    error_message = "Please enter valid CIDRs for your DB subnets."
  }

  validation {
    condition = length([ for sub in var.vpc_db_subnets : sub ]) == 2 || length([ for sub in var.vpc_db_subnets : sub ]) == 3
    error_message = "You must have 2 or 3 DB subnets."
  }
}

variable "vpc_lambda_subnets" {
  type = map(object({
    sub_cidr = string
  }))

  validation {
    condition = alltrue([ for cidr in var.vpc_lambda_subnets : can(cidrnetmask(cidr.sub_cidr)) ])
    error_message = "Please enter valid CIDRs for your Lambda subnets."
  }

  validation {
    condition = length([ for sub in keys(var.vpc_lambda_subnets) : sub ]) == length([ for sub in keys(var.vpc_db_subnets) : sub ])
    error_message = "Please use same amount of subnets for DB and Lambda."
  }
}
