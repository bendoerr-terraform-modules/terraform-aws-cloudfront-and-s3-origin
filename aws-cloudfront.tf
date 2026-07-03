#trivy:ignore:AVD-AWS-0010 MEDIUM: Distribution does not have logging enabled
#trivy:ignore:AVD-AWS-0011 HIGH: Distribution does not utilise a WAF
resource "aws_cloudfront_distribution" "site" {
  enabled = true
  comment = module.label_site.id
  tags    = module.label_site.tags

  price_class         = "PriceClass_100"
  aliases             = flatten([[local.default_alias], local.extra_aliases])
  http_version        = "http2"
  default_root_object = var.default_root_object
  is_ipv6_enabled     = true

  origin {
    origin_id                = module.label_site.id
    domain_name              = module.s3_site.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  dynamic "origin" {
    for_each = { for o in var.additional_origins : o.origin_id => o }
    content {
      origin_id   = origin.value.origin_id
      domain_name = origin.value.domain_name
      origin_path = origin.value.origin_path

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id           = module.label_site.id
    compress                   = true
    viewer_protocol_policy     = "https-only"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.default.id
    response_headers_policy_id = local.response_headers_policy_id

    dynamic "function_association" {
      for_each = var.function_associations
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = ordered_cache_behavior.value.target_origin_id
      allowed_methods          = ordered_cache_behavior.value.allowed_methods
      cached_methods           = ordered_cache_behavior.value.cached_methods
      cache_policy_id          = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id
      # Same viewer-side response headers policy as the default behavior so the
      # security headers strategy (var.security_headers) applies to API
      # responses too.
      response_headers_policy_id = local.response_headers_policy_id
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = true
    }
  }

  dynamic "custom_error_response" {
    for_each = var.enable_spa_error_handling ? toset(["403", "404"]) : []
    content {
      error_code         = custom_error_response.value
      response_code      = 200
      response_page_path = format("/%s", coalesce(var.default_root_object, "index.html"))
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method             = "sni-only"
  }

  lifecycle {
    precondition {
      condition     = var.security_headers != "custom" || var.response_headers_policy_id != null
      error_message = "When var.security_headers = \"custom\", var.response_headers_policy_id must be set to a non-null CloudFront response headers policy ID."
    }

    # Per-prefix DNS validation lives on extra_domain_prefixes; the total FQDN
    # length depends on domain_zone_name too, so the cap check goes here where
    # both variables are in scope.
    precondition {
      condition = alltrue([
        for prefix in var.extra_domain_prefixes :
        length("${prefix}.${var.domain_zone_name}") <= 253
      ])
      error_message = "Each FQDN formed by joining var.extra_domain_prefixes[*] with var.domain_zone_name must be at most 253 characters total (DNS limit). One or more prefixes combined with the zone name would exceed this; shorten the prefix(es) or use a shorter zone name."
    }
  }
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = module.label_site.id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "default" {
  name = "Managed-CachingOptimized"
}
