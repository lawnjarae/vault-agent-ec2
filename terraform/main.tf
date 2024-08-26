provider "vault" {
}

resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv-v2"
  description = "Key-Value v2 secrets engine"
}

resource "vault_kv_secret_v2" "important_api_key" {
  mount = vault_mount.kvv2.path
  name  = "brownfield-app-secrets"

  data_json = jsonencode({
    api_key     = "api-key-value"
    secret_data = "some-very-secret-data"
  })
}

resource "vault_database_secrets_mount" "postgres" {
  path        = "postgres"
  description = "PostgreSQL secrets engine"

  postgresql {
    name           = "db2"
    username       = "postgres"
    password       = "postgrespassword"
    connection_url = "postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable"
    verify_connection = true
    allowed_roles = [
      "dev1",
    ]
  }
}

resource "vault_database_secret_backend_role" "dev1" {
  name    = "dev1"
  backend = vault_database_secrets_mount.postgres.path
  db_name = vault_database_secrets_mount.postgres.postgresql[0].name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
  ]
  default_ttl = 60
  max_ttl = 60
}

# resource "vault_database_secret_backend_role" "your_postgres_role" {
#   backend = vault_mount.postgres.path
#   name    = "your-postgres-role"
#   db_name = vault_database_secret_backend_connection.postgres.name
#   creation_statements = [
#     "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
#     "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
#   ]
#   default_ttl = "1m"
#   max_ttl     = "24h"
# }

resource "vault_policy" "brownfield_policy" {
  name = "brownfield"

  policy = <<EOT
path "secret/data/brownfield-app-secrets" {
  capabilities = ["read"]
}

path "postgres/creds/dev1" {
  capabilities = ["read"]
}
EOT
}


resource "vault_auth_backend" "brownfield-approle" {
  type = "approle"
  path = "brownfield"
}

resource "vault_approle_auth_backend_role" "brownfield_role" {
  backend            = vault_auth_backend.brownfield-approle.path
  role_name          = "brownfield-role"
  token_policies     = ["default", vault_policy.brownfield_policy.name]
  token_ttl          = "3600"
  token_max_ttl      = "43200"
  token_num_uses     = 0
  secret_id_num_uses = 0
  secret_id_ttl      = 0
}

# The secret id and role id files and all of this aren't needed as the agent script will take care of it.
# resource "vault_approle_auth_backend_role_secret_id" "brownfield_secret_id" {
#   backend   = vault_auth_backend.brownfield-approle.path
#   role_name = vault_approle_auth_backend_role.brownfield_role.role_name
# }

# resource "local_file" "role_id_file" {
#   content  = vault_approle_auth_backend_role.brownfield_role.role_id
#   filename = "${path.module}/role_id.txt"
# }

# resource "local_file" "secret_id_file" {
#   content  = vault_approle_auth_backend_role_secret_id.brownfield_secret_id.secret_id
#   filename = "${path.module}/secret_id.txt"
# }
