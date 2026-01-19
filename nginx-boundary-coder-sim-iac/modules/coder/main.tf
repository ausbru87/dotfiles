#------------------------------------------------------------------------------
# Coder Module - Coder OSS Deployment
#
# Deploys Coder OSS (Open Source) with:
# - In-cluster PostgreSQL for simplicity
# - Wildcard subdomain routing for workspace apps (e.g., 5173-ws-user.domain.com)
# - NGINX Ingress integration
#
# Key configuration: CODER_WILDCARD_ACCESS_URL
# This tells Coder how workspace apps should be accessed via subdomains.
# Without this, workspace apps won't route correctly through the NGINX boundary.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Namespace
#------------------------------------------------------------------------------

resource "kubernetes_namespace" "coder" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "coder"
      "app.kubernetes.io/part-of" = "coder"
    }
  }
}

#------------------------------------------------------------------------------
# PostgreSQL - In-cluster database for simulation
# For production, use RDS or CloudNative-PG
#------------------------------------------------------------------------------

resource "random_password" "postgres" {
  length  = 24
  special = false  # Keep it simple for connection strings
}

resource "helm_release" "postgresql" {
  count = var.postgres_host == "" ? 1 : 0

  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "14.0.0"
  namespace  = kubernetes_namespace.coder.metadata[0].name

  values = [yamlencode({
    auth = {
      username = var.postgres_user
      password = random_password.postgres.result
      database = var.postgres_database
    }
    primary = {
      persistence = {
        size = "10Gi"
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }
  })]
}

#------------------------------------------------------------------------------
# Coder Helm Release
#------------------------------------------------------------------------------

resource "helm_release" "coder" {
  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "2.17.0"  # Use latest stable
  namespace  = kubernetes_namespace.coder.metadata[0].name

  # Wait for PostgreSQL to be ready
  depends_on = [helm_release.postgresql]

  values = [yamlencode({
    coder = {
      env = [
        {
          # Primary access URL for the Coder dashboard
          name  = "CODER_ACCESS_URL"
          value = var.access_url
        },
        {
          # CRITICAL: Wildcard URL for workspace apps
          # This enables subdomain-based routing like:
          # https://5173-myworkspace-myuser.coder.example.com
          # Without this, workspace apps won't work through NGINX
          name  = "CODER_WILDCARD_ACCESS_URL"
          value = var.wildcard_access_url
        },
        {
          # PostgreSQL connection string
          name  = "CODER_PG_CONNECTION_URL"
          value = var.postgres_host != "" ? "postgres://${var.postgres_user}@${var.postgres_host}/${var.postgres_database}?sslmode=require" : "postgres://${var.postgres_user}:${random_password.postgres.result}@postgresql.${var.namespace}.svc.cluster.local:5432/${var.postgres_database}?sslmode=disable"
        }
      ]

      ingress = {
        enable    = true
        className = var.ingress_class_name
        host      = var.ingress_host
        
        # Wildcard ingress for workspace apps
        wildcardHost = "*.${var.ingress_host}"
        
        annotations = {
          # NGINX-specific annotations for Coder
          "nginx.ingress.kubernetes.io/proxy-body-size"       = "0"
          "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "3600"
          "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "3600"
          "nginx.ingress.kubernetes.io/proxy-buffering"       = "off"
          
          # WebSocket support for terminal and apps
          "nginx.ingress.kubernetes.io/websocket-services"    = "coder"
          
          # Connection upgrade for WebSockets
          "nginx.ingress.kubernetes.io/configuration-snippet" = <<-EOF
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          EOF
        }
      }

      service = {
        type = "ClusterIP"  # Expose via Ingress only
      }
    }
  })]
}

#------------------------------------------------------------------------------
# Kubernetes Ingress for Coder
# Separate ingress for more control over routing
#------------------------------------------------------------------------------

resource "kubernetes_ingress_v1" "coder" {
  metadata {
    name      = "coder"
    namespace = kubernetes_namespace.coder.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                         = var.ingress_class_name
      "nginx.ingress.kubernetes.io/proxy-body-size"         = "0"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"      = "3600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"      = "3600"
      "nginx.ingress.kubernetes.io/ssl-redirect"            = "true"
      "nginx.ingress.kubernetes.io/websocket-services"      = "coder"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    # TLS for both main domain and wildcard
    tls {
      hosts       = [var.ingress_host, "*.${var.ingress_host}"]
      secret_name = "coder-tls"
    }

    # Main Coder dashboard
    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "coder"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Wildcard rule for workspace apps
    # This catches all subdomain traffic like:
    # 5173-workspace-user.coder.example.com
    rule {
      host = "*.${var.ingress_host}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "coder"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.coder]
}
