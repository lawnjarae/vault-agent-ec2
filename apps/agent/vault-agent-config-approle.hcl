pid_file = "/tmp/vault-agent-pid"

vault {
  address = "https://vault-cluster-public-vault-5440cd29.f3de9287.z1.hashicorp.cloud:8200"
}

auto_auth {
  method "approle" {
    namespace = "admin/ibm_mq"
    mount_path = "auth/brownfield"
    config = {
      role_id_file_path = "./role-id.txt"
      secret_id_file_path = "./secret-id.txt"
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/opt/vault/vault-agent/token-dir/vault-token-via-agent"
    }
  }
}
# Vault Agent cache configuration
# cache {
# //   use_auto_auth_token = true
# }

template {
  source      = "./get-certs-and-chain.ctmpl"
  destination =  "/var/mqm/qmgrs/QM1/ssl/vault-agent-template-cache"

  command = "/opt/vault/vault-agent/update-one-qm.sh"
}