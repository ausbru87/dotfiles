#------------------------------------------------------------------------------
# NGINX Boundary + Coder Simulation Environment
# Root module - orchestrates all infrastructure components
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

#------------------------------------------------------------------------------
# Provider Configuration
#------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "coder-nginx-boundary-sim"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes provider - configured after EKS is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# VPC Module - Network Foundation
#------------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # Tags for EKS auto-discovery
  eks_cluster_name = local.eks_cluster_name
}

#------------------------------------------------------------------------------
# EKS Module - Kubernetes Cluster
#------------------------------------------------------------------------------

module "eks" {
  source = "./modules/eks"

  environment    = var.environment
  cluster_name   = local.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids

  node_instance_type = var.eks_node_instance_type
  node_desired_count = var.eks_node_count
  node_min_count     = 1
  node_max_count     = var.eks_node_count + 2
}

#------------------------------------------------------------------------------
# NGINX Ingress Controller - Boundary Gateway
#------------------------------------------------------------------------------

module "nginx_boundary" {
  source = "./modules/nginx-boundary"

  depends_on = [module.eks]

  environment  = var.environment
  domain_name  = local.domain_name
  nlb_dns_name = "" # Will be populated after creation

  # TLS configuration
  enable_tls       = var.enable_tls
  tls_cert_arn     = var.tls_cert_arn
  use_self_signed  = var.tls_cert_arn == ""
}

#------------------------------------------------------------------------------
# Coder Deployment
#------------------------------------------------------------------------------

module "coder" {
  source = "./modules/coder"

  depends_on = [module.nginx_boundary]

  environment = var.environment
  namespace   = "coder"

  # Access URLs - configured for wildcard subdomain routing
  access_url          = "https://${local.domain_name}"
  wildcard_access_url = "https://*.${local.domain_name}"

  # Database - use in-cluster PostgreSQL for simulation
  postgres_host     = "" # Empty = deploy in-cluster
  postgres_user     = "coder"
  postgres_database = "coder"

  # Ingress class for NGINX routing
  ingress_class_name = "nginx"
  ingress_host       = local.domain_name
}

#------------------------------------------------------------------------------
# Windows Client - Untrusted Zone Test Machine
#------------------------------------------------------------------------------

module "windows_client" {
  source = "./modules/windows-client"

  environment   = var.environment
  instance_type = var.windows_instance_type

  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids[0]
  
  # Allow RDP from specified CIDR (default: anywhere for simulation)
  allowed_rdp_cidrs = var.allowed_rdp_cidrs

  # Coder URL for testing (added to desktop shortcut)
  coder_url = "https://${local.domain_name}"
}

#------------------------------------------------------------------------------
# Route53 DNS (Optional)
#------------------------------------------------------------------------------

module "dns" {
  source = "./modules/dns"
  count  = var.enable_route53 ? 1 : 0

  domain_name     = var.domain_name
  nlb_dns_name    = module.nginx_boundary.nlb_dns_name
  nlb_zone_id     = module.nginx_boundary.nlb_zone_id
  create_wildcard = true
}

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------

locals {
  eks_cluster_name = "coder-sim-${var.environment}"
  
  # If no domain provided, use nip.io with NLB IP
  domain_name = var.domain_name != "" ? var.domain_name : "${module.nginx_boundary.nlb_dns_name}.nip.io"
}
