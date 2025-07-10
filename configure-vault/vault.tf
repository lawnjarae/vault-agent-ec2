resource "vault_namespace" "demo_namespace" {
  path      = "brownfield_app"
}

resource "vault_mount" "kvv2" {
  namespace   = vault_namespace.demo_namespace.path_fq
  path        = "secret"
  type        = "kv-v2"
  description = "Key-Value v2 secrets engine"
}

resource "vault_kv_secret_v2" "important_api_key" {
  namespace = vault_namespace.demo_namespace.path_fq
  mount     = vault_mount.kvv2.path
  name      = "brownfield-app-secrets"

  data_json = jsonencode({
    api_key     = "api-key-value"
    secret_data = "some-very-secret-data"
  })
}

# resource "vault_database_secrets_mount" "postgres" {
#   depends_on = [
#     aws_rds_cluster_instance.db
#   ]
#   namespace   = vault_namespace.demo_namespace.path_fq
#   path        = "postgres"
#   description = "PostgreSQL secrets engine"

#   postgresql {
#     name              = local.database_name
#     username          = "demo_user"
#     password          = random_string.db_password.result
#     connection_url    = "postgresql://{{username}}:{{password}}@${aws_rds_cluster.db.endpoint}:${aws_rds_cluster.db.port}/${local.database_name}"
#     verify_connection = true
#     allowed_roles = [
#       "dev1",
#     ]
#   }
# }

# resource "vault_database_secret_backend_role" "dev1" {
#   namespace = vault_namespace.demo_namespace.path_fq
#   name      = "dev1"
#   db_name   = local.database_name
#   backend   = vault_database_secrets_mount.postgres.path
#   creation_statements = [
#     "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
#     "GRANT SELECT ON pg_stat_activity TO \"{{name}}\";",
#   ]
#   default_ttl = 30
#   max_ttl     = 60
# }

resource "vault_jwt_auth_backend" "jwt_config" {
  namespace = vault_namespace.demo_namespace.path_fq
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
}

resource "vault_policy" "tfc_policy" {
  namespace = vault_namespace.demo_namespace.path_fq
  name   = "tfc-policy"
  policy = file("${path.module}/tfc-policy.hcl")
}

resource "vault_jwt_auth_backend_role" "tfc_role" {
  namespace = vault_namespace.demo_namespace.path_fq
  backend           = vault_jwt_auth_backend.jwt_config.path
  role_name         = "tfc-role"
  role_type         = "jwt"
  user_claim        = "terraform_full_workspace"
  bound_audiences   = ["vault.workload.identity"]
  bound_claims_type = "glob"

  bound_claims = {
    sub = "organization:carson:project:MCBC:workspace:*:run_phase:*"
  }

  token_policies   = [vault_policy.tfc_policy.name, vault_policy.engine-policy.name]
  token_ttl  = "1200"
}


# Create a policy that we'll map to the brownfield AppRole. This policy allows for the reading of static secrets
# at secret/brownfield-app-secrets and also to create dynamic credentials for postgres that's configured
# on the postgres mount.
resource "vault_policy" "brownfield_policy" {
  namespace = vault_namespace.demo_namespace.path_fq
  name      = "brownfield"

  policy = <<EOT
path "secret/data/brownfield-app-secrets" {
  capabilities = ["read"]
}

path "postgres/creds/dev1" {
  capabilities = ["read"]
}

# Enable secrets engine
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}

# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo", "patch" ]
}

EOT
}

# Create the AppRole auth mount on the path "brownfield"
resource "vault_auth_backend" "brownfield-approle" {
  namespace = vault_namespace.demo_namespace.path_fq
  type      = "approle"
  path      = "brownfield"
}

# Create the AppRole role and map our policy to it. This AppRole will not expire and
# has unlimited number of uses.
resource "vault_approle_auth_backend_role" "brownfield_role" {
  namespace          = vault_namespace.demo_namespace.path_fq
  backend            = vault_auth_backend.brownfield-approle.path
  role_name          = "brownfield-role"
  token_policies     = ["default", vault_policy.brownfield_policy.name, vault_policy.engine-policy.name]
  token_ttl          = "3600"
  token_max_ttl      = "43200"
  token_num_uses     = 0
  secret_id_num_uses = 0
  secret_id_ttl      = 0
}

# Create a secret id for the previously created role. 
# resource "vault_approle_auth_backend_role_secret_id" "brownfield_secret_id" {
#   namespace = vault_namespace.demo_namespace.path_fq
#   backend   = vault_auth_backend.brownfield-approle.path
#   role_name = vault_approle_auth_backend_role.brownfield_role.role_name
# }




# This was already commented out in the original code, but leaving it here for reference.
# resource "vault_auth_backend" "aws" {
#   namespace   = vault_namespace.demo_namespace.path_fq
#   type        = "aws"
#   description = "AWS Auth Method"
# }

# Requires Vault 1.17+
# resource "vault_aws_auth_backend_client" "example" {
#   namespace               = vault_namespace.demo_namespace.path_fq
#   identity_token_audience = "<TOKEN_AUDIENCE>"
#   identity_token_ttl      = ""
#   role_arn                = "arn:aws:iam::515812054002:role/aws_justin.jarae_test-admin"
# }

# resource "vault_aws_auth_backend_role" "example" {
#   namespace                = vault_namespace.demo_namespace.path_fq
#   backend                  = vault_auth_backend.aws.path
#   role                     = "brownfield-role"
#   auth_type                = "iam"
#   bound_iam_principal_arns = ["arn:aws:iam::515812054002:role/aws_justin.jarae_test-developer"]
#   token_policies           = ["default", "brownfield"]
#   token_ttl                = "60"
#   token_max_ttl            = "120"
# }