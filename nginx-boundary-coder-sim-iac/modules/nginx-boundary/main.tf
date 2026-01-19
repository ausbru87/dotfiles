#------------------------------------------------------------------------------
# NGINX Boundary Module - Ingress Gateway for Coder
#
# This module deploys NGINX Ingress Controller as the boundary between
# the untrusted zone (internet/Windows client) and trusted zone (Coder).
#
# Critical for Coder:
# - Wildcard subdomain routing (*.domain.com) for workspace apps
# - WebSocket support for terminal and IDE connections
# - Large header buffers for Coder's authentication headers
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# NGINX Ingress Controller via Helm
#------------------------------------------------------------------------------

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.9.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  # Wait for the NLB to be provisioned
  wait    = true
  timeout = 600

  values = [yamlencode({
    controller = {
      # Use Network Load Balancer for better performance
      service = {
        type = "LoadBalancer"
        annotations = {
          # AWS NLB configuration
          "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
          
          # Enable cross-zone load balancing
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        }
      }

      # NGINX configuration for Coder compatibility
      config = {
        # Large buffer sizes for Coder's auth headers and cookies
        "proxy-buffer-size"    = "16k"
        "proxy-buffers"        = "4 16k"
        "proxy-busy-buffers-size" = "16k"
        
        # Unlimited body size for file uploads in workspaces
        "proxy-body-size" = "0"
        
        # WebSocket support - CRITICAL for Coder terminal and apps
        "proxy-read-timeout"  = "3600"
        "proxy-send-timeout"  = "3600"
        
        # Keep connections alive for streaming
        "upstream-keepalive-timeout" = "3600"
        
        # Security headers
        "X-Frame-Options"        = "SAMEORIGIN"
        "X-Content-Type-Options" = "nosniff"
        "X-XSS-Protection"       = "1; mode=block"
        
        # Enable websocket upgrades globally
        "use-forwarded-headers" = "true"
        
        # Real IP configuration for proper logging
        "compute-full-forwarded-for" = "true"
        "use-proxy-protocol"         = "false"
      }

      # Resource limits
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      # Enable metrics for monitoring
      metrics = {
        enabled = true
      }
    }
  })]
}

#------------------------------------------------------------------------------
# Self-Signed TLS Certificate
# Used when no ACM certificate is provided
# For production, use proper certificates via ACM or cert-manager
#------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  count     = var.use_self_signed ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  count           = var.use_self_signed ? 1 : 0
  private_key_pem = tls_private_key.ca[0].private_key_pem

  subject {
    common_name  = var.domain_name
    organization = "Coder Simulation"
  }

  # Wildcard SAN for workspace subdomains
  dns_names = [
    var.domain_name,
    "*.${var.domain_name}"
  ]

  validity_period_hours = 8760  # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

#------------------------------------------------------------------------------
# Kubernetes Secret for TLS Certificate
#------------------------------------------------------------------------------

resource "kubernetes_secret" "tls" {
  count = var.use_self_signed ? 1 : 0

  metadata {
    name      = "coder-tls"
    namespace = "ingress-nginx"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.ca[0].cert_pem
    "tls.key" = tls_private_key.ca[0].private_key_pem
  }

  depends_on = [helm_release.nginx_ingress]
}

#------------------------------------------------------------------------------
# Data source to get NLB details after creation
#------------------------------------------------------------------------------

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}
