#------------------------------------------------------------------------------
# DNS Module Variables
#------------------------------------------------------------------------------

variable "domain_name" {
  description = "Domain name for Coder (must have existing Route53 hosted zone)"
  type        = string
}

variable "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  type        = string
}

variable "nlb_zone_id" {
  description = "Route53 zone ID of the NLB (for alias records)"
  type        = string
  default     = ""
}

variable "create_wildcard" {
  description = "Create wildcard DNS record for workspace apps"
  type        = bool
  default     = true
}
