locals {
  customer_name      = "brownfield"
  app_service_name   = "demo_app"
  public_subnet_cidr = length(var.public_subnets) == 0 ? null_resource.auto_public_subnet_cidrs.*.triggers.cidr_block[0] : var.public_subnets[0]
  customer_id        = "${random_string.identifier.result}-${local.customer_name}"
  demo_name          = "dynamic-secrets-with-postgres"
  demo_id            = "${local.demo_name}-${local.customer_id}"
  global_id          = lower(substr(base64encode(local.demo_id), 0, 6))
  resources_prefix   = "${local.customer_name}-${local.global_id}"
  vpc_cidr           = "10.0.0.0/16"
  azs                = slice(data.aws_availability_zones.available.names, 0, 3)
  # database_name      = "demodb${random_string.database_identifier.result}"
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# resource "random_string" "database_identifier" {
#   length  = 4
#   special = false
#   numeric = false
#   upper   = false
# }

resource "random_string" "identifier" {
  length  = 4
  special = false
}

resource "null_resource" "auto_public_subnet_cidrs" {
  count = length(data.aws_availability_zones.available.names)

  triggers = {
    cidr_block = cidrsubnet(cidrsubnet(var.cidr, 2, 3), length(data.aws_availability_zones.available.names), count.index)
  }
}
