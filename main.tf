module "label_site" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = var.name
}

locals {
  default_alias = format("%s.%s", module.label_site.dns_name, var.domain_zone_name)
  extra_aliases = formatlist("%s.%s", var.extra_domain_prefixes, var.domain_zone_name)
}
