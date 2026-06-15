module "label_site" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "1.0.0"
  context = var.context
  name    = var.name
}

locals {
  default_alias = format("%s.%s", module.label_site.dns_name, var.domain_zone_name)
  extra_aliases = formatlist("%s.%s", var.extra_domain_prefixes, var.domain_zone_name)

  # AWS-published static ID for the managed `SecurityHeadersPolicy`. Hardcoded rather than
  # resolved via `data "aws_cloudfront_response_headers_policy"` so the module does not
  # require the caller's apply role to hold `cloudfront:ListResponseHeadersPolicies`. AWS
  # documents these IDs as stable for managed policies.
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
  managed_security_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

  response_headers_policy_id = (
    var.security_headers == "managed" ? local.managed_security_headers_policy_id :
    var.security_headers == "custom" ? var.response_headers_policy_id :
    null
  )
}
