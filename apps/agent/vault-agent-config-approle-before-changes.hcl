pid_file = "/tmp/vault-agent-pid"

vault {
  address = "$VAULT_ADDR"
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
// cache {
//   use_auto_auth_token = true
// }

template {
  source      = "./pki-cert.ctmpl"
  # destination =  "/home/ec2-user/agent/renewed/cert.pem"
  destination =  "/var/mqm/qmgrs/QM1/ssl/cert.pem"
}

template {
  source      = "./pki-key.ctmpl"
  destination =  "/var/mqm/qmgrs/QM1/ssl/key.pem"
  # destination =  "/home/ec2-user/agent/renewed/key.pem"
}

template {
  source      = "./pki-ca.ctmpl"
  destination =  "/var/mqm/qmgrs/QM1/ssl/ca.pem"
  # destination =  "/home/ec2-user/agent/renewed/ca.pem"
}