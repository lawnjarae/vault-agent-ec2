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

template {
  source      = "./get-certs-and-chain.ctmpl"
  destination =  "/var/mqm/qmgrs/QM1/ssl/vault-agent-template-cache"
  exec {
    command = ["/opt/vault/vault-agent/update-one-qm-clean.sh"]
  }
}