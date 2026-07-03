output "s3_bucket_id" {
  value       = module.cloudfront_with_s3_origin.s3_bucket_id
  description = "The ID of the S3 bucket used for the CloudFront origin."
}

output "cloudfront_distribution_id" {
  value       = module.cloudfront_with_s3_origin.cloudfront_distribution_id
  description = "The ID of the CloudFront distribution."
}

output "cloudfront_distribution_alias_domain_name" {
  value       = module.cloudfront_with_s3_origin.cloudfront_distribution_alias_domain_name
  description = "The primary alias domain name of the CloudFront distribution (the zone apex when use_apex_domain = true)."
}
