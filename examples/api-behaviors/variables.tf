variable "namespace" {
  type        = string
  description = "The context namespace"
}

variable "route53_profile" {
  type        = string
  description = "Dedicated AWS profile for accessing Route53"
  nullable    = false
}

variable "route53_zone_id" {
  type        = string
  description = "The ZoneID for the Route53 Zone"
  nullable    = false
}

variable "route53_zone_name" {
  type        = string
  description = "The Name of the Route53 Zone"
  nullable    = false
}
