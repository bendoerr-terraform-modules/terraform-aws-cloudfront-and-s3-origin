terraform {
  required_version = ">= 0.13"
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
  name    = "status"

  domain_zone_name      = var.route53_zone_name
  domain_zone_id        = var.route53_zone_id
  extra_domain_prefixes = [format("status.test.%s", var.namespace)]

  providers = {
    aws.route53 = aws.route53
  }
}
