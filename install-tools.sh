#!/bin/bash
# install-tools.sh - Install DevOps/IaC tools for Coder workspaces
# Usage: ./install-tools.sh [--all | tool1 tool2 ...]
# Example: ./install-tools.sh terraform terragrunt aws-cli

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

# Tool versions (override with environment variables)
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.7.0}"
TERRAGRUNT_VERSION="${TERRAGRUNT_VERSION:-0.54.0}"
KUBECTL_VERSION="${KUBECTL_VERSION:-1.29.0}"
HELM_VERSION="${HELM_VERSION:-3.14.0}"
OC_VERSION="${OC_VERSION:-4.14}"

# Installation directories
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local}"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l)  ARCH="arm" ;;
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ==============================================================================
# Helper Functions
# ==============================================================================

ensure_bin_dir() {
    mkdir -p "$BIN_DIR"
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        export PATH="$BIN_DIR:$PATH"
        log_info "Added $BIN_DIR to PATH"
    fi
}

check_installed() {
    command -v "$1" &>/dev/null
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$output"
    else
        log_error "Neither curl nor wget found"
        return 1
    fi
}

# ==============================================================================
# Tool Installers
# ==============================================================================

install_terraform() {
    local version="${1:-$TERRAFORM_VERSION}"
    
    if check_installed terraform; then
        local current_version
        current_version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        if [[ "$current_version" == "$version" ]]; then
            log_info "Terraform $version already installed"
            return 0
        fi
    fi
    
    log_info "Installing Terraform $version..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    local url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${OS}_${ARCH}.zip"
    download_file "$url" "$tmp_dir/terraform.zip"
    unzip -q "$tmp_dir/terraform.zip" -d "$tmp_dir"
    mv "$tmp_dir/terraform" "$BIN_DIR/terraform"
    chmod +x "$BIN_DIR/terraform"
    
    log_success "Terraform $version installed"
}

install_terragrunt() {
    local version="${1:-$TERRAGRUNT_VERSION}"
    
    if check_installed terragrunt; then
        local current_version
        current_version=$(terragrunt --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr -d 'v')
        if [[ "$current_version" == "$version" ]]; then
            log_info "Terragrunt $version already installed"
            return 0
        fi
    fi
    
    log_info "Installing Terragrunt $version..."
    local url="https://github.com/gruntwork-io/terragrunt/releases/download/v${version}/terragrunt_${OS}_${ARCH}"
    download_file "$url" "$BIN_DIR/terragrunt"
    chmod +x "$BIN_DIR/terragrunt"
    
    log_success "Terragrunt $version installed"
}

install_aws_cli() {
    if check_installed aws; then
        log_info "AWS CLI already installed: $(aws --version)"
        return 0
    fi
    
    log_info "Installing AWS CLI v2..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    if [[ "$OS" == "linux" ]]; then
        local url="https://awscli.amazonaws.com/awscli-exe-linux-${ARCH/amd64/x86_64}.zip"
        download_file "$url" "$tmp_dir/awscliv2.zip"
        unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
        "$tmp_dir/aws/install" --install-dir "$INSTALL_DIR/aws-cli" --bin-dir "$BIN_DIR" --update
    elif [[ "$OS" == "darwin" ]]; then
        log_warn "On macOS, please install AWS CLI via: brew install awscli"
        return 1
    fi
    
    log_success "AWS CLI installed"
}

install_azure_cli() {
    if check_installed az; then
        log_info "Azure CLI already installed: $(az version --query '\"azure-cli\"' -o tsv)"
        return 0
    fi
    
    log_info "Installing Azure CLI..."
    
    if [[ "$OS" == "linux" ]]; then
        # Check for package manager
        if command -v apt-get &>/dev/null; then
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        elif command -v yum &>/dev/null; then
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
            sudo yum install -y azure-cli
        else
            log_warn "No supported package manager found. Install manually: https://docs.microsoft.com/cli/azure/install-azure-cli"
            return 1
        fi
    elif [[ "$OS" == "darwin" ]]; then
        log_warn "On macOS, please install Azure CLI via: brew install azure-cli"
        return 1
    fi
    
    log_success "Azure CLI installed"
}

install_gcloud() {
    if check_installed gcloud; then
        log_info "Google Cloud SDK already installed: $(gcloud version --format='value(Google Cloud SDK)')"
        return 0
    fi
    
    log_info "Installing Google Cloud SDK..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    local gcloud_arch
    case $ARCH in
        amd64) gcloud_arch="x86_64" ;;
        arm64) gcloud_arch="arm" ;;
        *) gcloud_arch="$ARCH" ;;
    esac
    
    local url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-latest-${OS}-${gcloud_arch}.tar.gz"
    download_file "$url" "$tmp_dir/gcloud.tar.gz"
    tar -xzf "$tmp_dir/gcloud.tar.gz" -C "$HOME"
    "$HOME/google-cloud-sdk/install.sh" --quiet --path-update false --command-completion false
    
    # Create symlinks
    ln -sf "$HOME/google-cloud-sdk/bin/gcloud" "$BIN_DIR/gcloud"
    ln -sf "$HOME/google-cloud-sdk/bin/gsutil" "$BIN_DIR/gsutil"
    ln -sf "$HOME/google-cloud-sdk/bin/bq" "$BIN_DIR/bq"
    
    log_success "Google Cloud SDK installed"
}

install_kubectl() {
    local version="${1:-$KUBECTL_VERSION}"
    
    if check_installed kubectl; then
        local current_version
        current_version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' | tr -d 'v')
        if [[ "$current_version" == "$version" ]]; then
            log_info "kubectl $version already installed"
            return 0
        fi
    fi
    
    log_info "Installing kubectl $version..."
    local url="https://dl.k8s.io/release/v${version}/bin/${OS}/${ARCH}/kubectl"
    download_file "$url" "$BIN_DIR/kubectl"
    chmod +x "$BIN_DIR/kubectl"
    
    log_success "kubectl $version installed"
}

install_openshift_cli() {
    local version="${1:-$OC_VERSION}"
    
    if check_installed oc; then
        log_info "OpenShift CLI already installed: $(oc version --client 2>/dev/null | head -1)"
        return 0
    fi
    
    log_info "Installing OpenShift CLI..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    # Get latest stable for the major version
    local url="https://mirror.openshift.com/pub/openshift-v4/${ARCH/amd64/x86_64}/clients/ocp/stable-${version}/openshift-client-${OS}.tar.gz"
    download_file "$url" "$tmp_dir/oc.tar.gz"
    tar -xzf "$tmp_dir/oc.tar.gz" -C "$tmp_dir"
    mv "$tmp_dir/oc" "$BIN_DIR/oc"
    chmod +x "$BIN_DIR/oc"
    
    log_success "OpenShift CLI installed"
}

install_helm() {
    local version="${1:-$HELM_VERSION}"
    
    if check_installed helm; then
        local current_version
        current_version=$(helm version --template='{{.Version}}' 2>/dev/null | tr -d 'v')
        if [[ "$current_version" == "$version" ]]; then
            log_info "Helm $version already installed"
            return 0
        fi
    fi
    
    log_info "Installing Helm $version..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    local url="https://get.helm.sh/helm-v${version}-${OS}-${ARCH}.tar.gz"
    download_file "$url" "$tmp_dir/helm.tar.gz"
    tar -xzf "$tmp_dir/helm.tar.gz" -C "$tmp_dir"
    mv "$tmp_dir/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
    chmod +x "$BIN_DIR/helm"
    
    log_success "Helm $version installed"
}

install_aws_cdk() {
    if check_installed cdk; then
        log_info "AWS CDK already installed: $(cdk --version)"
        return 0
    fi
    
    log_info "Installing AWS CDK..."
    
    if ! check_installed node; then
        log_warn "Node.js not found. Installing via nvm..."
        install_nodejs
    fi
    
    npm install -g aws-cdk
    
    log_success "AWS CDK installed"
}

install_nodejs() {
    if check_installed node; then
        log_info "Node.js already installed: $(node --version)"
        return 0
    fi
    
    log_info "Installing Node.js via nvm..."
    
    # Install nvm
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]]; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    
    # Load nvm
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    
    # Install latest LTS
    nvm install --lts
    nvm use --lts
    
    log_success "Node.js installed"
}

install_tflint() {
    if check_installed tflint; then
        log_info "TFLint already installed: $(tflint --version | head -1)"
        return 0
    fi
    
    log_info "Installing TFLint..."
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    
    log_success "TFLint installed"
}

install_tfsec() {
    if check_installed tfsec; then
        log_info "tfsec already installed: $(tfsec --version)"
        return 0
    fi
    
    log_info "Installing tfsec..."
    local url="https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-${OS}-${ARCH}"
    download_file "$url" "$BIN_DIR/tfsec"
    chmod +x "$BIN_DIR/tfsec"
    
    log_success "tfsec installed"
}

install_checkov() {
    if check_installed checkov; then
        log_info "Checkov already installed: $(checkov --version)"
        return 0
    fi
    
    log_info "Installing Checkov..."
    
    if ! check_installed pip3; then
        log_warn "pip3 not found. Please install Python 3 first."
        return 1
    fi
    
    pip3 install --user checkov
    
    log_success "Checkov installed"
}

install_infracost() {
    if check_installed infracost; then
        log_info "Infracost already installed: $(infracost --version)"
        return 0
    fi
    
    log_info "Installing Infracost..."
    curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh -s -- -b "$BIN_DIR"
    
    log_success "Infracost installed"
}

install_terraform_docs() {
    if check_installed terraform-docs; then
        log_info "terraform-docs already installed: $(terraform-docs --version)"
        return 0
    fi
    
    log_info "Installing terraform-docs..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    local url="https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-v0.17.0-${OS}-${ARCH}.tar.gz"
    download_file "$url" "$tmp_dir/terraform-docs.tar.gz"
    tar -xzf "$tmp_dir/terraform-docs.tar.gz" -C "$tmp_dir"
    mv "$tmp_dir/terraform-docs" "$BIN_DIR/terraform-docs"
    chmod +x "$BIN_DIR/terraform-docs"
    
    log_success "terraform-docs installed"
}

install_kubectx() {
    if check_installed kubectx; then
        log_info "kubectx already installed"
        return 0
    fi
    
    log_info "Installing kubectx and kubens..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    git clone --depth 1 https://github.com/ahmetb/kubectx.git "$tmp_dir/kubectx"
    mv "$tmp_dir/kubectx/kubectx" "$BIN_DIR/kubectx"
    mv "$tmp_dir/kubectx/kubens" "$BIN_DIR/kubens"
    chmod +x "$BIN_DIR/kubectx" "$BIN_DIR/kubens"
    
    log_success "kubectx and kubens installed"
}

install_k9s() {
    if check_installed k9s; then
        log_info "k9s already installed: $(k9s version --short)"
        return 0
    fi
    
    log_info "Installing k9s..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" RETURN
    
    local url="https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz"
    download_file "$url" "$tmp_dir/k9s.tar.gz"
    tar -xzf "$tmp_dir/k9s.tar.gz" -C "$tmp_dir"
    mv "$tmp_dir/k9s" "$BIN_DIR/k9s"
    chmod +x "$BIN_DIR/k9s"
    
    log_success "k9s installed"
}

install_jq() {
    if check_installed jq; then
        log_info "jq already installed: $(jq --version)"
        return 0
    fi
    
    log_info "Installing jq..."
    local url="https://github.com/jqlang/jq/releases/latest/download/jq-${OS}-${ARCH}"
    download_file "$url" "$BIN_DIR/jq"
    chmod +x "$BIN_DIR/jq"
    
    log_success "jq installed"
}

install_yq() {
    if check_installed yq; then
        log_info "yq already installed: $(yq --version)"
        return 0
    fi
    
    log_info "Installing yq..."
    local url="https://github.com/mikefarah/yq/releases/latest/download/yq_${OS}_${ARCH}"
    download_file "$url" "$BIN_DIR/yq"
    chmod +x "$BIN_DIR/yq"
    
    log_success "yq installed"
}

# ==============================================================================
# Main
# ==============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TOOLS...]

Install DevOps and Infrastructure tools for Coder workspaces.

OPTIONS:
    --all           Install all tools
    --core          Install core IaC tools (terraform, terragrunt, aws-cli, azure-cli, gcloud, oc, cdk)
    --k8s           Install Kubernetes tools (kubectl, helm, kubectx, k9s)
    --security      Install security/linting tools (tflint, tfsec, checkov)
    --utils         Install utility tools (jq, yq, terraform-docs, infracost)
    -h, --help      Show this help message

AVAILABLE TOOLS:
    terraform       HashiCorp Terraform
    terragrunt      Terragrunt wrapper
    aws-cli         AWS CLI v2
    azure-cli       Azure CLI
    gcloud          Google Cloud SDK
    kubectl         Kubernetes CLI
    oc              OpenShift CLI
    helm            Kubernetes package manager
    cdk             AWS CDK
    tflint          Terraform linter
    tfsec           Terraform security scanner
    checkov         Infrastructure security scanner
    infracost       Cloud cost estimation
    terraform-docs  Terraform documentation generator
    kubectx         Kubernetes context switcher
    k9s             Kubernetes TUI
    jq              JSON processor
    yq              YAML processor
    nodejs          Node.js (via nvm)

EXAMPLES:
    $(basename "$0") --all                    # Install everything
    $(basename "$0") --core                   # Install core IaC tools
    $(basename "$0") terraform terragrunt     # Install specific tools
    $(basename "$0") --k8s --security         # Install tool groups

ENVIRONMENT VARIABLES:
    TERRAFORM_VERSION    Terraform version (default: $TERRAFORM_VERSION)
    TERRAGRUNT_VERSION   Terragrunt version (default: $TERRAGRUNT_VERSION)
    KUBECTL_VERSION      kubectl version (default: $KUBECTL_VERSION)
    BIN_DIR              Binary install directory (default: $BIN_DIR)

EOF
}

install_core() {
    install_terraform
    install_terragrunt
    install_aws_cli
    install_azure_cli
    install_gcloud
    install_openshift_cli
    install_kubectl
    install_aws_cdk
}

install_k8s() {
    install_kubectl
    install_helm
    install_kubectx
    install_k9s
}

install_security() {
    install_tflint
    install_tfsec
    install_checkov
}

install_utils() {
    install_jq
    install_yq
    install_terraform_docs
    install_infracost
}

install_all() {
    install_core
    install_k8s
    install_security
    install_utils
}

main() {
    ensure_bin_dir
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --all)
                install_all
                ;;
            --core)
                install_core
                ;;
            --k8s)
                install_k8s
                ;;
            --security)
                install_security
                ;;
            --utils)
                install_utils
                ;;
            terraform)
                install_terraform
                ;;
            terragrunt)
                install_terragrunt
                ;;
            aws-cli|aws)
                install_aws_cli
                ;;
            azure-cli|az)
                install_azure_cli
                ;;
            gcloud|gcp)
                install_gcloud
                ;;
            kubectl)
                install_kubectl
                ;;
            oc|openshift)
                install_openshift_cli
                ;;
            helm)
                install_helm
                ;;
            cdk|aws-cdk)
                install_aws_cdk
                ;;
            tflint)
                install_tflint
                ;;
            tfsec)
                install_tfsec
                ;;
            checkov)
                install_checkov
                ;;
            infracost)
                install_infracost
                ;;
            terraform-docs)
                install_terraform_docs
                ;;
            kubectx)
                install_kubectx
                ;;
            k9s)
                install_k9s
                ;;
            jq)
                install_jq
                ;;
            yq)
                install_yq
                ;;
            nodejs|node)
                install_nodejs
                ;;
            *)
                log_error "Unknown tool: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    echo ""
    log_success "Tool installation complete!"
    log_info "Run 'source ~/.bashrc' to update your PATH"
}

main "$@"
