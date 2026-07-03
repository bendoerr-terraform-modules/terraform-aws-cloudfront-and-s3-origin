terraform {
  # 1.9.0 floor: var.ordered_cache_behaviors' validation cross-references
  # var.additional_origins, which requires Terraform >= 1.9.
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.route53]
    }
  }
}
