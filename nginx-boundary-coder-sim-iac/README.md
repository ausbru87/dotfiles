# NGINX Boundary + Coder Simulation Environment

This Terraform project deploys a complete simulation environment for testing Coder OSS
behind an NGINX reverse proxy boundary, with a Windows client in an "untrusted" zone
for end-to-end access testing.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS us-west-2                                       │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                         VPC (10.0.0.0/16)                                   ││
│  │                                                                             ││
│  │  ┌─────────────────────────────────┐  ┌──────────────────────────────────┐ ││
│  │  │      Trusted Zone               │  │      Untrusted Zone              │ ││
│  │  │      (Private Subnets)          │  │      (Public Subnet)             │ ││
│  │  │                                 │  │                                  │ ││
│  │  │  ┌───────────────────────────┐  │  │  ┌────────────────────────────┐  │ ││
│  │  │  │        EKS Cluster        │  │  │  │    Windows EC2 Client     │  │ ││
│  │  │  │                           │  │  │  │                            │  │ ││
│  │  │  │  ┌─────────┐ ┌─────────┐  │  │  │  │  - RDP Access              │  │ ││
│  │  │  │  │  Coder  │ │ Coder   │  │  │  │  │  - Browser for testing     │  │ ││
│  │  │  │  │ Server  │ │Workspaces│  │  │  │  │  - Simulates external     │  │ ││
│  │  │  │  └────▲────┘ └─────────┘  │  │  │  │    user access             │  │ ││
│  │  │  │       │                   │  │  │  └────────────┬───────────────┘  │ ││
│  │  │  └───────┼───────────────────┘  │  │               │                  │ ││
│  │  │          │                      │  │               │                  │ ││
│  │  │  ┌───────┴───────────────────┐  │  │               │                  │ ││
│  │  │  │   NGINX Ingress (NLB)     │◄─┼──┼───────────────┘                  │ ││
│  │  │  │                           │  │  │                                  │ ││
│  │  │  │  - TLS Termination        │  │  │                                  │ ││
│  │  │  │  - Wildcard subdomain     │  │  │                                  │ ││
│  │  │  │    routing for workspaces │  │  │                                  │ ││
│  │  │  │  - Rate limiting          │  │  │                                  │ ││
│  │  │  └───────────────────────────┘  │  │                                  │ ││
│  │  │                                 │  │                                  │ ││
│  │  └─────────────────────────────────┘  └──────────────────────────────────┘ ││
│  │                                                                             ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │  Route53 (Optional)                                                         ││
│  │  *.coder.example.com → NLB                                                  ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. VPC (`modules/vpc/`)
- CIDR: 10.0.0.0/16
- 3 public subnets (untrusted zone, NAT gateways, load balancers)
- 3 private subnets (trusted zone, EKS nodes)
- NAT Gateway for private subnet egress
- Security groups isolating trusted/untrusted zones

### 2. EKS Cluster (`modules/eks/`)
- Kubernetes 1.29
- Managed node group with t3.large instances
- Private API endpoint (accessed via NGINX boundary only)
- IRSA for AWS integrations

### 3. Coder Deployment (`modules/coder/`)
- Coder OSS via Helm chart
- PostgreSQL (RDS or in-cluster)
- Configured for wildcard subdomain workspace access
- Vite workspace template pre-loaded

### 4. NGINX Boundary (`modules/nginx-boundary/`)
- NGINX Ingress Controller via Helm
- NLB for external access
- TLS termination with self-signed or ACM certs
- Wildcard routing: `*.coder.example.com`
- Security headers and rate limiting

### 5. Windows Client (`modules/windows-client/`)
- Windows Server 2022 EC2 instance
- In public subnet (untrusted zone)
- RDP access enabled
- Pre-installed: Chrome, VS Code
- Used to test Coder access through NGINX boundary

### 6. Vite Template (`templates/vite-workspace/`)
- Basic Coder workspace template
- Node.js + Vite development server
- Exposes port 5173 via `coder_app`
- Tests subdomain routing through NGINX

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- kubectl
- helm
- Domain name (optional, can use NLB DNS + nip.io)

## Quick Start

```bash
# 1. Initialize Terraform
cd nginx-boundary-coder-sim-iac
terraform init

# 2. Review and customize variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 3. Deploy infrastructure
terraform plan
terraform apply

# 4. Get outputs
terraform output

# 5. Connect to Windows client via RDP
# Use the windows_rdp_address output
# Default credentials in terraform output

# 6. From Windows client, access Coder
# Open browser to: https://coder.<your-domain>
# Create workspace from Vite template
# Access Vite dev server via workspace subdomain
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `environment` | Environment name | `sim` |
| `domain_name` | Base domain for Coder | `""` (uses nip.io) |
| `eks_node_instance_type` | EKS node size | `t3.large` |
| `eks_node_count` | Number of EKS nodes | `2` |
| `windows_instance_type` | Windows EC2 size | `t3.medium` |
| `enable_route53` | Create Route53 records | `false` |

## Testing Workflow

1. **RDP to Windows Client**
   - Use the RDP address from `terraform output windows_rdp_address`
   - Credentials from `terraform output windows_admin_password`

2. **Access Coder Dashboard**
   - Open Chrome on Windows client
   - Navigate to `https://coder.<domain>` (or NLB DNS)
   - Create initial admin user

3. **Create Vite Workspace**
   - Use the pre-loaded "vite-workspace" template
   - Wait for workspace to start

4. **Test Subdomain Routing**
   - Access Vite dev server via workspace app
   - URL pattern: `https://5173-<workspace>-<user>.coder.<domain>`
   - Verify hot reload works through NGINX boundary

## Security Considerations

⚠️ **This is a simulation environment - not for production use**

- Self-signed TLS certificates (or Let's Encrypt for testing)
- Windows client has public IP for RDP access
- Coder uses default OSS configuration
- No SSO/OIDC integration

## Cost Estimate

Approximate monthly cost (us-west-2):
- EKS Control Plane: ~$73
- EKS Nodes (2x t3.large): ~$120
- NAT Gateway: ~$45
- NLB: ~$25
- Windows EC2 (t3.medium): ~$30
- EBS Storage: ~$10
- **Total: ~$300/month**

💡 Use `terraform destroy` when not testing to minimize costs.

## Cleanup

```bash
terraform destroy
```

## Troubleshooting

### Can't access Coder from Windows client
1. Check security groups allow traffic from untrusted to trusted zone
2. Verify NGINX ingress is healthy: `kubectl get pods -n ingress-nginx`
3. Check Coder pods: `kubectl get pods -n coder`

### Workspace subdomain not routing
1. Verify wildcard DNS is configured
2. Check NGINX ingress logs: `kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx`
3. Ensure Coder `CODER_WILDCARD_ACCESS_URL` is set correctly

### Vite hot reload not working
1. Vite websocket needs proper proxy configuration
2. Check NGINX ingress supports websocket upgrades
3. Verify no intermediate proxies stripping upgrade headers

## License

MIT
