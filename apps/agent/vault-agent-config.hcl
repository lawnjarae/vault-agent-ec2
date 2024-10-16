pid_file = "/tmp/vault-agent-pid"

vault {
  address = "$VAULT_ADDR"
}

auto_auth {
  method "aws" {
    namespace = "admin/hc-justin-jarae/brownfield_app"
    mount_path = "auth/aws"
    config = {
      type = "iam"
      role = "aws_justin.jarae_test-developer"
    }
  }

  sink "file" {
    config = {
      path = "/home/ubuntu/vault-token-via-agent"
    }
  }
}

template_config {
  static_secret_render_interval = "15s"
}

# Vault Agent cache configuration
// cache {
//   use_auto_auth_token = true
// }

template {
  source      = "./static-secrets.ctmpl"
  destination = "../brownfield-app/config/application-static.properties"
  exec {
    command = ["./handle-updates.sh"]
  }
}

template {
  source      = "./dynamic-credentials.ctmpl"
  destination = "../brownfield-app/config/application-dynamic.properties"
  exec {
    command = ["./handle-updates.sh"]
  }
}
