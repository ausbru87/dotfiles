#------------------------------------------------------------------------------
# NGINX Boundary Module Outputs
#------------------------------------------------------------------------------

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = try(data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname, "pending")
}

output "nlb_zone_id" {
  description = "Route53 zone ID for the NLB (for alias records)"
  value       = "" # Would need additional data source to get this
}

output "ingress_class_name" {
  description = "Ingress class name for use in Ingress resources"
  value       = "nginx"
}

output "tls_secret_name" {
  description = "Name of the TLS secret (if self-signed)"
  value       = var.use_self_signed ? kubernetes_secret.tls[0].metadata[0].name : ""
}
