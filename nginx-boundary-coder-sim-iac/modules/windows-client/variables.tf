#------------------------------------------------------------------------------
# Windows Client Module Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (should be public subnet in untrusted zone)"
  type        = string
}

variable "allowed_rdp_cidrs" {
  description = "CIDR blocks allowed to RDP to this instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "coder_url" {
  description = "Coder URL for desktop shortcut and instructions"
  type        = string
}
