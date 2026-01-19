#------------------------------------------------------------------------------
# VPC Module Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (untrusted zone)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets (trusted zone)"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}
