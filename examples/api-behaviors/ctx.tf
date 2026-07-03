module "context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "0.5.1"
  namespace = var.namespace
  role      = "cloudfront-s3-example"
  region    = "us-east-1"
  project   = "api-behaviors"
  long_dns  = true
}
