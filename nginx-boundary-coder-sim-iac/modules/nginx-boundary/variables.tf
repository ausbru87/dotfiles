#------------------------------------------------------------------------------
# NGINX Boundary Module Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for TLS certificate"
  type        = string
}

variable "nlb_dns_name" {
  description = "NLB DNS name (passed in for circular reference avoidance)"
  type        = string
  default     = ""
}

variable "enable_tls" {
  description = "Enable TLS termination"
  type        = bool
  default     = true
}

variable "tls_cert_arn" {
  description = "ACM certificate ARN (if not using self-signed)"
  type        = string
  default     = ""
}

variable "use_self_signed" {
  description = "Use self-signed TLS certificate"
  type        = bool
  default     = true
}
