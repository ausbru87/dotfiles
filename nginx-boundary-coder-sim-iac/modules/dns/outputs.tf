#------------------------------------------------------------------------------
# DNS Module Outputs
#------------------------------------------------------------------------------

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "main_record_fqdn" {
  description = "FQDN for the main Coder record"
  value       = aws_route53_record.main.fqdn
}

output "wildcard_record_fqdn" {
  description = "FQDN for the wildcard record"
  value       = var.create_wildcard ? aws_route53_record.wildcard[0].fqdn : ""
}
