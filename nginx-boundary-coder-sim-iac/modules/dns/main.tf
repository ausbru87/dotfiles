#------------------------------------------------------------------------------
# DNS Module - Route53 Configuration (Optional)
#
# Creates DNS records for Coder access:
# - A record for main domain → NLB
# - Wildcard A record for workspace apps → NLB
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data source for existing hosted zone
#------------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

#------------------------------------------------------------------------------
# A Record for main Coder domain
# coder.example.com → NLB
#------------------------------------------------------------------------------

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.nlb_dns_name
    zone_id                = var.nlb_zone_id != "" ? var.nlb_zone_id : data.aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }
}

#------------------------------------------------------------------------------
# Wildcard A Record for workspace apps
# *.coder.example.com → NLB
# This enables subdomain-based routing like:
# 5173-myworkspace-myuser.coder.example.com
#------------------------------------------------------------------------------

resource "aws_route53_record" "wildcard" {
  count = var.create_wildcard ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.nlb_dns_name
    zone_id                = var.nlb_zone_id != "" ? var.nlb_zone_id : data.aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }
}
