#------------------------------------------------------------------------------
# EKS Module - Kubernetes Cluster for Coder
#
# This module creates an EKS cluster in the trusted zone (private subnets).
# Key features:
# - Managed node group for simplified node lifecycle
# - IRSA (IAM Roles for Service Accounts) for pod-level AWS permissions
# - Private API endpoint with public access for initial setup
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EKS Cluster IAM Role
# The cluster needs permissions to manage AWS resources on your behalf
#------------------------------------------------------------------------------

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

#------------------------------------------------------------------------------
# EKS Cluster
#------------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true   # Allow access from within VPC
    endpoint_public_access  = true   # Allow access from outside (for kubectl)
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Enable control plane logging for debugging
  enabled_cluster_log_types = ["api", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Name = var.cluster_name
  }
}

#------------------------------------------------------------------------------
# Cluster Security Group
# Controls traffic to/from the EKS control plane
#------------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

#------------------------------------------------------------------------------
# Node Group IAM Role
# Worker nodes need permissions to join cluster and pull images
#------------------------------------------------------------------------------

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Required policies for EKS worker nodes
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

#------------------------------------------------------------------------------
# Managed Node Group
# AWS manages the EC2 instances, we just specify the configuration
#------------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnets  # Nodes in trusted zone

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  # Use latest EKS-optimized AMI
  ami_type = "AL2_x86_64"

  # Enable SSH access (optional, for debugging)
  # remote_access {
  #   ec2_ssh_key = var.ssh_key_name
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_registry_policy,
  ]

  tags = {
    Name = "${var.cluster_name}-nodes"
  }
}

#------------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# Allows Kubernetes service accounts to assume IAM roles
# This is the secure way to give pods AWS permissions
#------------------------------------------------------------------------------

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc"
  }
}
