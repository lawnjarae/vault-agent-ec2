data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Get the required info from Vault
data "vault_namespace" "namespace" {
  path = "brownfield_app"
}

data "vault_auth_backend" "brownfield_approle" {
  namespace = data.vault_namespace.namespace.path_fq
  path      = "brownfield"
}

data "vault_approle_auth_backend_role_id" "brownfield_role_id" {
  namespace = data.vault_namespace.namespace.path_fq
  backend   = data.vault_auth_backend.brownfield_approle.path
  role_name = "brownfield-role"
}

resource "vault_approle_auth_backend_role_secret_id" "brownfield_secret_id" {
  namespace = data.vault_namespace.namespace.path_fq
  backend   = data.vault_auth_backend.brownfield_approle.path
  role_name = "brownfield-role"
}
# End Vault

resource "aws_instance" "instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  tags = {
    Name = "${local.customer_name}-web"
  }
}

resource "null_resource" "configure_and_run_demo" {
  depends_on = [
    aws_eip_association.ip_assoc
  ]

  # triggers = {
  #   build_number = timestamp()
  # }

  provisioner "file" {
    source      = "apps/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = aws_eip.public_ip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo CONFIG_HOME=/home/ubuntu/brownfield-app/config | sudo tee -a /etc/profile",
      "echo VAULT_ADDR=${var.vault_public_endpoint} | sudo tee -a /etc/profile",
      "echo VAULT_NAMESPACE=admin/${data.vault_namespace.namespace.path_fq} | sudo tee -a /etc/profile",
      "cd /home/ubuntu/agent",
      "chmod +x handle-updates.sh",
      "echo ${data.vault_approle_auth_backend_role_id.brownfield_role_id.role_id} > role-id.txt",
      "echo ${vault_approle_auth_backend_role_secret_id.brownfield_secret_id.secret_id} > secret-id.txt",
      "echo ${vault_approle_auth_backend_role_secret_id.brownfield_secret_id.secret_id} > secret-id.txt.bak",
      "sudo apt update",
      "cd /home/ubuntu/startup-scripts",
      "chmod +x install.sh",
      "sudo ./install.sh",
      "sudo systemctl start brownfield-app"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = aws_eip.public_ip.public_ip
    }
  }
}

locals {
  private_key_filename = "${random_string.identifier.result}-ssh-key.pem"
}

resource "tls_private_key" "key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "key_pair" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.key.public_key_openssh
}


# Create a secret id for the previously created role. 
# resource "vault_approle_auth_backend_role_secret_id" "brownfield_secret_id" {
#   namespace = vault_namespace.demo_namespace.path_fq
#   backend   = vault_auth_backend.brownfield-approle.path
#   role_name = vault_approle_auth_backend_role.brownfield_role.role_name