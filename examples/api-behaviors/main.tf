terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Route53 zones can often be in a different account. They cost $0.50 to exist
# so if we are trying to keep costs down we may want to only have the minimum
# needed to function.
provider "aws" {
  region  = "us-east-1"
  alias   = "route53"
  profile = var.route53_profile
}

module "cloudfront_with_s3_origin" {
  source = "../.."

  context = module.context.shared
  name    = "app"

  domain_zone_name = var.route53_zone_name
  domain_zone_id   = var.route53_zone_id

  # Serve the label-derived subdomain; set true to serve the zone apex instead.
  use_apex_domain = false

  # Route /api/* to an API Gateway regional endpoint on the same distribution,
  # ahead of the default S3 behavior. origin_path carries the API stage.
  additional_origins = [{
    origin_id   = "api"
    domain_name = "example-api.execute-api.us-east-1.amazonaws.com"
    origin_path = "/api"
  }]
  ordered_cache_behaviors = [
    { path_pattern = "/api/*", target_origin_id = "api" },
  ]

  providers = {
    aws.route53 = aws.route53
  }
}
