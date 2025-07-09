# resource "random_string" "db_password" {
#   length  = 16
#   special = false
# }

# resource "aws_db_subnet_group" "database" {
#   name       = "${local.resources_prefix}-db-subnet-group"
#   subnet_ids = module.vpc.public_subnets
# }

# resource "aws_security_group" "database" {
#   name        = "${local.resources_prefix}-sg-database"
#   description = "database"
#   vpc_id      = module.vpc.vpc_id

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "database_ingress_rule" {
#   depends_on        = [module.vpc]
#   security_group_id = aws_security_group.database.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
# }

# resource "aws_vpc_security_group_egress_rule" "database_egress_rule" {
#   depends_on        = [module.vpc]
#   security_group_id = aws_security_group.database.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_rds_cluster" "db" {
#   depends_on                   = [module.vpc]
#   cluster_identifier           = "${local.resources_prefix}-rds"
#   apply_immediately            = true
#   availability_zones           = local.azs
#   database_name                = local.database_name
#   master_username              = "demo_user"
#   performance_insights_enabled = false
#   master_password              = random_string.db_password.result
#   storage_type                 = "aurora-iopt1"
#   engine                       = "aurora-postgresql"
#   db_subnet_group_name         = aws_db_subnet_group.database.name
#   skip_final_snapshot          = true
#   vpc_security_group_ids       = [aws_security_group.database.id]
# }

# resource "aws_rds_cluster_instance" "db" {
#   depends_on = [
#     module.vpc,
#     aws_vpc_security_group_ingress_rule.database_ingress_rule,
#     aws_vpc_security_group_egress_rule.database_egress_rule,
#   ]
#   count                        = 1
#   apply_immediately            = true
#   identifier                   = "${local.resources_prefix}-db-${count.index}"
#   cluster_identifier           = aws_rds_cluster.db.id
#   instance_class               = "db.t3.medium"
#   engine                       = aws_rds_cluster.db.engine
#   engine_version               = aws_rds_cluster.db.engine_version
#   db_subnet_group_name         = aws_rds_cluster.db.db_subnet_group_name
#   monitoring_interval          = 0
#   publicly_accessible          = true
#   performance_insights_enabled = false
# }
