#------------------------------------------------------------------------------
# VPC Module Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (used for subnet tagging)"
  type        = string
}
