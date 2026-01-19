#------------------------------------------------------------------------------
# Vite Workspace Template for Coder
#
# This template creates a Kubernetes-based workspace with:
# - Node.js development environment
# - Vite dev server running on port 5173
# - Subdomain-based app routing (critical for testing NGINX boundary)
#
# The Vite dev server is exposed via coder_app with subdomain=true, which
# means it will be accessible at: https://5173-<workspace>-<user>.<domain>
#
# This tests the critical path through NGINX's wildcard subdomain routing.
#------------------------------------------------------------------------------

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

#------------------------------------------------------------------------------
# Coder Data Sources
#------------------------------------------------------------------------------

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

#------------------------------------------------------------------------------
# Parameters
#------------------------------------------------------------------------------

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "CPU cores for the workspace"
  default      = "2"
  type         = "number"
  mutable      = true
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "Memory in GB for the workspace"
  default      = "4"
  type         = "number"
  mutable      = true
}

#------------------------------------------------------------------------------
# Coder Agent
# The agent runs inside the workspace and handles:
# - Terminal connections
# - App proxying (including Vite dev server)
# - File sync, SSH, etc.
#------------------------------------------------------------------------------

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Install Node.js 20 if not present
    if ! command -v node &> /dev/null; then
      echo "Installing Node.js 20..."
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install -y nodejs
    fi
    
    # Create Vite project if it doesn't exist
    if [ ! -d ~/vite-app ]; then
      echo "Creating Vite React project..."
      cd ~
      npm create vite@latest vite-app -- --template react
      cd vite-app
      npm install
    fi
    
    # Start Vite dev server in background
    # --host is CRITICAL: allows connections from outside localhost
    # Without --host, Vite only listens on 127.0.0.1 and won't be
    # accessible through the Coder proxy/NGINX boundary
    cd ~/vite-app
    echo "Starting Vite dev server..."
    nohup npm run dev -- --host > /tmp/vite.log 2>&1 &
    
    echo "Vite dev server started on port 5173"
    echo "Access via the 'Vite Dev Server' app in Coder"
  EOF

  # Metadata displayed in Coder UI
  metadata {
    display_name = "CPU Usage"
    key          = "cpu"
    script       = "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"
    interval     = 5
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "memory"
    script       = "free -m | awk 'NR==2{printf \"%.1f%%\", $3*100/$2}'"
    interval     = 5
    timeout      = 1
  }
}

#------------------------------------------------------------------------------
# Vite Dev Server App
#
# subdomain = true is the KEY setting here!
# This enables access via: https://5173-<workspace>-<user>.<domain>
# rather than path-based routing like: https://<domain>/@<user>/<workspace>/apps/vite
#
# Subdomain routing is more reliable for web apps that expect to be at
# the root path, and it's what we're testing through the NGINX boundary.
#------------------------------------------------------------------------------

resource "coder_app" "vite" {
  agent_id     = coder_agent.main.id
  slug         = "vite"
  display_name = "Vite Dev Server"
  icon         = "https://vitejs.dev/logo.svg"
  
  # CRITICAL: Enable subdomain-based routing
  # This creates URLs like: https://5173-workspace-user.coder.example.com
  subdomain = true
  
  # Share with workspace owner only (can be "authenticated" or "public")
  share = "owner"
  
  # Port where Vite runs
  url = "http://localhost:5173"
  
  # Health check to show app status in UI
  healthcheck {
    url       = "http://localhost:5173"
    interval  = 5
    threshold = 3
  }
}

#------------------------------------------------------------------------------
# VS Code Web App (bonus)
#------------------------------------------------------------------------------

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code"
  display_name = "VS Code"
  icon         = "https://raw.githubusercontent.com/coder/coder/main/site/static/icon/code.svg"
  subdomain    = true
  share        = "owner"
  url          = "http://localhost:8080?folder=/home/coder/vite-app"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 5
    threshold = 3
  }
}

#------------------------------------------------------------------------------
# Kubernetes Pod
# The actual workspace container running in EKS
#------------------------------------------------------------------------------

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = "coder"
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = data.coder_workspace.me.name
    }
  }

  spec {
    # Don't restart on failure - let Coder manage lifecycle
    restart_policy = "Never"
    
    container {
      name  = "dev"
      image = "codercom/enterprise-base:ubuntu"
      
      command = ["sh", "-c", coder_agent.main.init_script]

      resources {
        requests = {
          cpu    = "${data.coder_parameter.cpu.value}"
          memory = "${data.coder_parameter.memory.value}Gi"
        }
        limits = {
          cpu    = "${data.coder_parameter.cpu.value}"
          memory = "${data.coder_parameter.memory.value}Gi"
        }
      }

      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      # Workspace home directory
      volume_mount {
        name       = "home"
        mount_path = "/home/coder"
      }
    }

    volume {
      name = "home"
      empty_dir {}
    }
  }
}
