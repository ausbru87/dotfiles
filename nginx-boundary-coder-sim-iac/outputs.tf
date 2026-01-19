#------------------------------------------------------------------------------
# Outputs for NGINX Boundary + Coder Simulation Environment
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Access Information
#------------------------------------------------------------------------------

output "coder_url" {
  description = "URL to access Coder dashboard"
  value       = "https://${local.domain_name}"
}

output "coder_wildcard_url" {
  description = "Wildcard URL pattern for workspace apps"
  value       = "https://*.<workspace>.<user>.${local.domain_name}"
}

#------------------------------------------------------------------------------
# Windows Client Access
#------------------------------------------------------------------------------

output "windows_rdp_address" {
  description = "RDP connection address for Windows test client"
  value       = module.windows_client.public_ip
}

output "windows_admin_password" {
  description = "Administrator password for Windows client (retrieve via AWS console if using key pair)"
  value       = module.windows_client.admin_password
  sensitive   = true
}

#------------------------------------------------------------------------------
# Kubernetes Access
#------------------------------------------------------------------------------

output "eks_cluster_name" {
  description = "EKS cluster name for kubectl configuration"
  value       = module.eks.cluster_name
}

output "eks_configure_kubectl" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

#------------------------------------------------------------------------------
# Network Information
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = module.nginx_boundary.nlb_dns_name
}

#------------------------------------------------------------------------------
# Testing Instructions
#------------------------------------------------------------------------------

output "testing_instructions" {
  description = "Step-by-step testing instructions"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════╗
    ║           NGINX Boundary + Coder Simulation Environment          ║
    ╚══════════════════════════════════════════════════════════════════╝

    1. CONNECT TO WINDOWS CLIENT
       RDP Address: ${module.windows_client.public_ip}
       Username: Administrator
       Password: terraform output -raw windows_admin_password

    2. ACCESS CODER DASHBOARD (from Windows client browser)
       URL: https://${local.domain_name}
       - Create admin account on first access
       - Accept self-signed certificate warning

    3. CREATE VITE WORKSPACE
       - Click "Create Workspace"
       - Select "vite-workspace" template
       - Wait for workspace to start (~2 min)

    4. TEST SUBDOMAIN ROUTING
       - Click the "Vite Dev Server" app icon in workspace
       - URL will be: https://5173-<workspace>-<user>.${local.domain_name}
       - Verify page loads through NGINX boundary
       - Test hot reload by editing src/App.jsx

    5. CLEANUP
       terraform destroy

  EOT
}
