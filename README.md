# 🚀 Coder Workspace Dotfiles

Dotfiles optimized for **Terraform/Infrastructure as Code** development in [Coder](https://coder.com) workspaces.

## Features

- **Terraform & Terragrunt** - Aliases, functions, and vim support for HCL development
- **Multi-cloud CLI support** - AWS, Azure, GCP, and OpenShift integrations
- **Kubernetes tooling** - kubectl, helm, k9s aliases and completions
- **AWS CDK** - Node.js and CDK environment setup
- **Security tools** - TFLint, tfsec, Checkov, Infracost integrations
- **Quality of life** - Sensible git config, vim setup, tmux config, and shell enhancements

## Quick Start

### Option 1: One-liner Install (from GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh | bash
```

### Option 2: Clone and Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Option 3: Use with Coder Templates

Add to your Coder template's startup script:

```hcl
resource "coder_agent" "main" {
  # ...
  startup_script = <<-EOT
    # Install dotfiles
    if [ ! -d ~/.dotfiles ]; then
      git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
      ~/.dotfiles/install.sh
    fi
  EOT
}
```

## Install Tools

Install DevOps tools with the included script:

```bash
# Install all tools
./install-tools.sh --all

# Install core IaC tools (terraform, terragrunt, cloud CLIs)
./install-tools.sh --core

# Install specific tools
./install-tools.sh terraform terragrunt aws-cli kubectl

# See all options
./install-tools.sh --help
```

### Available Tools

| Category | Tools |
|----------|-------|
| **Core IaC** | terraform, terragrunt, aws-cli, azure-cli, gcloud, oc (OpenShift) |
| **Kubernetes** | kubectl, helm, kubectx, kubens, k9s |
| **Security** | tflint, tfsec, checkov |
| **Utilities** | jq, yq, terraform-docs, infracost |
| **CDK** | nodejs (via nvm), aws-cdk |

## What's Included

```
dotfiles/
├── install.sh           # Main installer script
├── install-tools.sh     # DevOps tools installer
├── .bashrc              # Shell configuration
├── .bash_terraform      # Terraform/IaC specific config
├── .gitconfig           # Git configuration
├── .gitignore_global    # Global gitignore
├── .vimrc               # Vim configuration (Terraform-optimized)
├── .tmux.conf           # Tmux configuration
├── .inputrc             # Readline configuration
└── README.md            # This file
```

## Key Aliases & Functions

### Terraform

| Alias | Command |
|-------|---------|
| `tf` | `terraform` |
| `tfi` | `terraform init` |
| `tfp` | `terraform plan` |
| `tfa` | `terraform apply` |
| `tfaa` | `terraform apply -auto-approve` |
| `tfd` | `terraform destroy` |
| `tfv` | `terraform validate` |
| `tff` | `terraform fmt` |
| `tfsl` | `terraform state list` |

**Functions:**
- `tfinit [env]` - Init with backend config for environment
- `tfplan [file]` - Plan with output file
- `tfcheck` - Format and validate
- `tgclean` - Clean terragrunt cache

### Terragrunt

| Alias | Command |
|-------|---------|
| `tg` | `terragrunt` |
| `tgi` | `terragrunt init` |
| `tgp` | `terragrunt plan` |
| `tga` | `terragrunt apply` |
| `tgra` | `terragrunt run-all` |
| `tgrap` | `terragrunt run-all plan` |

### AWS

| Alias/Function | Description |
|----------------|-------------|
| `aws-whoami` | Show current identity |
| `aws-profile [name]` | Switch/show AWS profile |
| `aws-assume-role <arn>` | Assume IAM role |
| `aws-unassume` | Clear assumed role |
| `ec2-ls` | List EC2 instances |
| `ecr-login` | Login to ECR |

### Azure

| Alias/Function | Description |
|----------------|-------------|
| `az-whoami` | Show current account |
| `az-sub [id]` | Switch/list subscriptions |
| `az-aks-creds <rg> <cluster>` | Get AKS credentials |
| `acr-login <name>` | Login to ACR |

### Google Cloud

| Alias/Function | Description |
|----------------|-------------|
| `gcp-whoami` | Show current account |
| `gcp-switch [project]` | Switch/list projects |
| `gke-creds <cluster> <zone>` | Get GKE credentials |
| `gcr-login` | Configure Docker for GCR |

### Kubernetes

| Alias | Command |
|-------|---------|
| `k` | `kubectl` |
| `kgp` | `kubectl get pods` |
| `kgpa` | `kubectl get pods --all-namespaces` |
| `kgs` | `kubectl get svc` |
| `kgd` | `kubectl get deployments` |
| `kl` | `kubectl logs -f` |
| `kex` | `kubectl exec -it` |
| `kaf` | `kubectl apply -f` |

### Multi-Cloud

- `cloud-status` - Show authentication status for all cloud providers

## Vim Keybindings

Leader key: `<Space>`

| Binding | Action |
|---------|--------|
| `<leader>ti` | `terraform init` |
| `<leader>tp` | `terraform plan` |
| `<leader>ta` | `terraform apply` |
| `<leader>tf` | `terraform fmt` (current file) |
| `<leader>e` | Toggle file explorer |
| `<leader>ff` | Find files (fzf) |

## Tmux Keybindings

Prefix: `Ctrl+a`

| Binding | Action |
|---------|--------|
| `Prefix + \|` | Split vertically |
| `Prefix + -` | Split horizontally |
| `Prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Prefix + T` | Terraform layout |
| `Prefix + K` | Kubernetes layout |
| `Prefix + S` | Sync panes (multi-server) |
| `Prefix + r` | Reload config |

## Customization

### Local Overrides

Create `~/.bashrc.local` for machine-specific settings:

```bash
# ~/.bashrc.local
export AWS_DEFAULT_REGION="eu-west-1"
export TF_VAR_environment="staging"
```

### Tool Versions

Override default versions via environment variables:

```bash
TERRAFORM_VERSION="1.6.0" ./install-tools.sh terraform
KUBECTL_VERSION="1.28.0" ./install-tools.sh kubectl
```

## Coder Integration

These dotfiles automatically detect Coder workspace environment variables:

- `CODER_WORKSPACE_NAME` - Displayed in prompt and tmux
- `CODER_WORKSPACE_OWNER_EMAIL` - Auto-configured in git
- `CODER_WORKSPACE_OWNER_NAME` - Auto-configured in git

## Requirements

- Bash 4.0+
- Git
- curl or wget
- unzip (for some tool installations)

## License

MIT
