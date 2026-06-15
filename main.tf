module "label_site" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"
  context = var.context
  name    = var.name
}

locals {
  default_alias = format("%s.%s", module.label_site.dns_name, var.domain_zone_name)
  extra_aliases = formatlist("%s.%s", var.extra_domain_prefixes, var.domain_zone_name)

  response_headers_policy_id = (
    var.security_headers == "managed" ? one(data.aws_cloudfront_response_headers_policy.security_headers[*].id) :
    var.security_headers == "custom" ? var.response_headers_policy_id :
    null
  )
}
