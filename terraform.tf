terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # vault = {
    #   source  = "hashicorp/vault"
    #   version = "~> 4.0"
    # }
    aws = {
      source  = "hashicorp/aws"
      version = "5.69.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
