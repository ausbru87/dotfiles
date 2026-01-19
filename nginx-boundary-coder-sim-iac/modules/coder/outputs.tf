#------------------------------------------------------------------------------
# Coder Module Outputs
#------------------------------------------------------------------------------

output "coder_url" {
  description = "URL to access Coder dashboard"
  value       = var.access_url
}

output "namespace" {
  description = "Kubernetes namespace where Coder is deployed"
  value       = kubernetes_namespace.coder.metadata[0].name
}

output "postgres_secret_name" {
  description = "Name of the PostgreSQL secret (if using in-cluster)"
  value       = var.postgres_host == "" ? "postgresql" : ""
}
