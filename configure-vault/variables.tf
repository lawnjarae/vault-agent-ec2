variable "vault_public_endpoint" {
  type    = string
  default = ""
}

variable "tfc_org_name" {
  description = "The name of the Terraform Cloud organization to use for this demo."
  type        = string
  default     = null
}

variable "tfc_project_name" {
  description = "The name of the Terraform Cloud project to use for this demo."
  type        = string
  default     = null
}