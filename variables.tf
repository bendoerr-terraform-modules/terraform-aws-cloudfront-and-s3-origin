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

  validation {
    condition = (
      var.s3_kms_key_arn == null ||
      can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:(key/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}|alias/[a-zA-Z0-9/_-]+)$", var.s3_kms_key_arn))
    )
    error_message = "var.s3_kms_key_arn must be null or a valid KMS ARN. Expected shape: arn:<partition>:kms:<region>:<account>:key/<uuid> or arn:<partition>:kms:<region>:<account>:alias/<name>. Aliases are accepted because S3 SSE configuration takes either form."
  }
}

variable "default_root_object" {
  type        = string
  default     = "index.html"
  description = "The default root object for the S3 bucket, typically used for web hosting."
  nullable    = true

  validation {
    condition = (
      var.default_root_object == null ||
      (length(var.default_root_object) > 0 && !startswith(var.default_root_object, "/"))
    )
    error_message = "var.default_root_object must be null or a non-empty path that does not start with '/'. The path is interpreted relative to the distribution root; a leading slash is a common mistake CloudFront silently rejects."
  }
}

variable "domain_zone_name" {
  type        = string
  description = "If setting a custom CNAME for the Cloudfront distribution this is the domain name for the zone."
  nullable    = false

  validation {
    condition     = can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}$", var.domain_zone_name))
    error_message = "var.domain_zone_name must be a valid lowercase domain name (e.g. \"example.com\"). Each label may contain lowercase alphanumerics and hyphens but must not start or end with a hyphen. Internationalized domain names should be passed in their punycode (xn--) form."
  }
}

variable "domain_zone_id" {
  type        = string
  description = "If setting a custom CNAME for the Cloudfront distribution this is the domain name for the zone."
  nullable    = false

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.domain_zone_id))
    error_message = "var.domain_zone_id must be a Route 53 hosted zone ID (e.g. \"Z1D633PJN98FT9\"): starts with an uppercase 'Z' followed by uppercase alphanumerics. If you have the zone name and not the ID, look it up via the Route 53 console or `aws route53 list-hosted-zones-by-name`."
  }
}

variable "extra_domain_prefixes" {
  type        = list(string)
  default     = []
  description = "Prefixes for additional custom domains to be associated with the CloudFront distribution. Each prefix is concatenated as '<prefix>.<domain_zone_name>' to form the final FQDN; multi-label prefixes (e.g. \"api.cdn\") are supported."
  nullable    = false

  validation {
    condition = alltrue([
      for prefix in var.extra_domain_prefixes :
      length(prefix) > 0 && length(prefix) <= 253 &&
      can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)(\\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$", prefix))
    ])
    error_message = "Each entry in var.extra_domain_prefixes must be one or more valid DNS labels separated by '.'. Each label: 1-63 lowercase alphanumerics or hyphens, not starting or ending with a hyphen. Total prefix length must not exceed 253 characters."
  }
}

variable "function_associations" {
  type = set(object({
    event_type   = string
    function_arn = string
  }))
  default     = []
  description = "A config block that triggers a lambda function with specific actions (maximum 4)."
  nullable    = false

  # CloudFront's hard limit is 4 function associations per cache behavior. This
  # module only configures the distribution's default_cache_behavior, so the
  # per-behavior limit is also the module-wide limit.
  validation {
    condition     = length(var.function_associations) <= 4
    error_message = "var.function_associations must contain at most 4 entries (CloudFront's per-cache-behavior limit; this module uses a single cache behavior)."
  }

  validation {
    condition = alltrue([
      for assoc in var.function_associations :
      contains(["viewer-request", "viewer-response", "origin-request", "origin-response"], assoc.event_type)
    ])
    error_message = "Each function_associations[*].event_type must be one of: viewer-request, viewer-response, origin-request, origin-response. Note that CloudFront Functions only support viewer-request and viewer-response; use Lambda@Edge for origin-request and origin-response."
  }

  validation {
    condition = alltrue([
      for assoc in var.function_associations :
      can(regex("^arn:aws[a-z-]*:cloudfront::[0-9]{12}:function/[a-zA-Z0-9_-]+$", assoc.function_arn)) ||
      can(regex("^arn:aws[a-z-]*:lambda:[a-z0-9-]+:[0-9]{12}:function:[a-zA-Z0-9_-]+:[0-9]+$", assoc.function_arn))
    ])
    error_message = "Each function_associations[*].function_arn must be either a CloudFront Function ARN (arn:<partition>:cloudfront::<account>:function/<name>) or a Lambda@Edge versioned function ARN (arn:<partition>:lambda:<region>:<account>:function:<name>:<version>). Lambda@Edge associations require a specific version number — CloudFront does not accept $LATEST."
  }

  # Cross-attribute check: origin-* event types are Lambda@Edge-only. A
  # CloudFront Function ARN paired with origin-request/origin-response will be
  # rejected by the CloudFront API at apply time; catch it here instead.
  validation {
    condition = alltrue([
      for assoc in var.function_associations :
      !contains(["origin-request", "origin-response"], assoc.event_type) ||
      !can(regex("^arn:aws[a-z-]*:cloudfront::", assoc.function_arn))
    ])
    error_message = "function_associations entries with event_type 'origin-request' or 'origin-response' must point to a Lambda@Edge ARN, not a CloudFront Function. CloudFront Functions only execute at the viewer edge."
  }
}

variable "enable_spa_error_handling" {
  type        = bool
  default     = false
  description = "Enable SPA error handling by redirecting 403 errors to / with 200 status code."
  nullable    = false
}

variable "security_headers" {
  type        = string
  default     = "managed"
  description = "Response headers policy strategy for the CloudFront distribution. One of: \"managed\" (attach AWS's Managed-SecurityHeadersPolicy — HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, X-XSS-Protection), \"custom\" (attach the policy at var.response_headers_policy_id — required when this is set), or \"none\" (no response headers policy attached)."
  nullable    = false

  validation {
    condition     = contains(["managed", "custom", "none"], var.security_headers)
    error_message = "var.security_headers must be one of: \"managed\", \"custom\", \"none\"."
  }
}

variable "response_headers_policy_id" {
  type        = string
  default     = null
  description = "CloudFront response headers policy ID. Required when var.security_headers = \"custom\"; ignored otherwise."
  nullable    = true

  validation {
    condition = (
      var.response_headers_policy_id == null ||
      can(regex("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$", var.response_headers_policy_id))
    )
    error_message = "var.response_headers_policy_id must be null or a CloudFront response headers policy ID in UUID format (e.g. \"67f7725c-6f97-4210-82d7-5512b31e9d03\"). If you have the policy ARN, the ID is the last path segment."
  }
}
