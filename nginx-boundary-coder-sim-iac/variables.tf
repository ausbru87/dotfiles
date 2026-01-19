#------------------------------------------------------------------------------
# Variables for NGINX Boundary + Coder Simulation Environment
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# General
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (used in resource naming and tags)"
  type        = string
  default     = "sim"
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Base domain name for Coder (e.g., coder.example.com). Leave empty to use nip.io"
  type        = string
  default     = ""
}

variable "enable_route53" {
  description = "Create Route53 DNS records (requires domain_name to be set)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# EKS Configuration
#------------------------------------------------------------------------------

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.large"
}

variable "eks_node_count" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

#------------------------------------------------------------------------------
# TLS Configuration
#------------------------------------------------------------------------------

variable "enable_tls" {
  description = "Enable TLS termination at NGINX ingress"
  type        = bool
  default     = true
}

variable "tls_cert_arn" {
  description = "ACM certificate ARN for TLS. Leave empty to use self-signed certificate"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Windows Client
#------------------------------------------------------------------------------

variable "windows_instance_type" {
  description = "EC2 instance type for Windows test client"
  type        = string
  default     = "t3.medium"
}

variable "allowed_rdp_cidrs" {
  description = "CIDR blocks allowed to RDP to Windows client"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open for simulation - restrict in production!
}
