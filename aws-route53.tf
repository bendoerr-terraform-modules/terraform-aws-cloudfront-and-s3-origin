resource "aws_route53_record" "alias" {
  for_each = toset(flatten([[local.default_alias], var.extra_domain_prefixes]))
  name     = each.key
  type     = "A"
  zone_id  = var.domain_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
  }

  provider = aws.route53
}
