module "vpc" {
  source                          = "terraform-aws-modules/vpc/aws"
  version                         = "5.13.0"
  name                            = "${local.resources_prefix}-vpc"
  cidr                            = local.vpc_cidr
  azs                             = local.azs
  private_subnets                 = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets                  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  create_database_subnet_group    = false
  database_subnet_enable_dns64    = false
  create_elasticache_subnet_group = false
  create_redshift_subnet_group    = false
  enable_nat_gateway              = true
  single_nat_gateway              = true
}

resource "aws_eip" "public_ip" {
  instance = aws_instance.instance.id
  domain   = "vpc"
}

resource "aws_eip_association" "ip_assoc" {
  instance_id   = aws_instance.instance.id
  allocation_id = aws_eip.public_ip.id
}
