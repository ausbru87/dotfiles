#------------------------------------------------------------------------------
# Windows Client Module Outputs
#------------------------------------------------------------------------------

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.windows.id
}

output "public_ip" {
  description = "Public IP address for RDP connection"
  value       = aws_instance.windows.public_ip
}

output "admin_password" {
  description = "Administrator password"
  value       = random_password.admin.result
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.windows.id
}
