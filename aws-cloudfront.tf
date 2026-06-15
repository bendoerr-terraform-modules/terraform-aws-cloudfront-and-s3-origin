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

data "aws_cloudfront_response_headers_policy" "security_headers" {
  count = var.security_headers == "managed" ? 1 : 0
  name  = "Managed-SecurityHeadersPolicy"
}
