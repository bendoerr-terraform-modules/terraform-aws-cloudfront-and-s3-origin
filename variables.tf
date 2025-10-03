variable "context" {
  type = object({
    attributes     = list(string)
    dns_namespace  = string
    environment    = string
    instance       = string
    instance_short = string
    namespace      = string
    region         = string
    region_short   = string
    role           = string
    role_short     = string
    project        = string
    tags           = map(string)
  })
  description = "Shared Context from Ben's terraform-null-context"
}

variable "name" {
  type        = string
  default     = "site"
  description = "The name of the site, used for naming resources and identifiers."
  nullable    = false
}

variable "s3_kms_key_arn" {
  type        = string
  default     = null
  description = "The ARN of the KMS key used for S3 server-side encryption."
  nullable    = true
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
  description = "The default root object for the S3 bucket, typically used for web hosting."
  nullable    = true
}

variable "domain_zone_name" {
  type        = string
  description = "If setting a custom CNAME for the Cloudfront distribution this is the domain name for the zone."
  nullable    = false
}

variable "domain_zone_id" {
  type        = string
  description = "If setting a custom CNAME for the Cloudfront distribution this is the domain name for the zone."
  nullable    = false
}

variable "extra_domain_prefixes" {
  type        = list(string)
  default     = []
  description = "Prefixes for additional custom domains to be associated with the CloudFront distribution."
  nullable    = false
}

variable "function_associations" {
  type = set(object({
    event_type   = string
    function_arn = string
  }))
  default     = []
  description = "A config block that triggers a lambda function with specific actions (maximum 4)."
  nullable    = false
}

variable "enable_spa_error_handling" {
  type        = bool
  default     = false
  description = "Enable SPA error handling by redirecting 403 errors to / with 200 status code."
  nullable    = false
}
