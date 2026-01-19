#------------------------------------------------------------------------------
# Coder Module Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Coder"
  type        = string
  default     = "coder"
}

variable "access_url" {
  description = "Primary access URL for Coder dashboard (e.g., https://coder.example.com)"
  type        = string
}

variable "wildcard_access_url" {
  description = "Wildcard URL for workspace apps (e.g., https://*.coder.example.com)"
  type        = string
}

variable "postgres_host" {
  description = "PostgreSQL host. Leave empty to deploy in-cluster PostgreSQL"
  type        = string
  default     = ""
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "coder"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "coder"
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx)"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Host for Coder ingress"
  type        = string
}
