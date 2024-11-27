output "vault_cluster_url" {
  value       = var.ddr_vault_public_endpoint
  description = "Use this URL Log into the Vault UI and explore the database configurations."
}

output "app_with_agent_url" {
  value       = "http://${aws_eip.public_ip.public_dns}:8080"
  description = "The URL of the web application that connects to the PostgreSQL database using dynamic credentials."
}

output "app_without_agent_url" {
  value       = "http://${aws_eip.public_ip.public_dns}:8084"
  description = "The URL of the web application that does not update any secrets."
}
