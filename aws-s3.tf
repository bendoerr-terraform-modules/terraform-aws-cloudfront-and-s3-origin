#trivy:ignore:AVD-AWS-0089 LOW: Bucket has logging disabled
#trivy:ignore:AVD-AWS-0090 MEDIUM: Bucket does not have versioning enabled
module "s3_site" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.0"

  bucket = module.label_site.id
  tags   = module.label_site.tags

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = var.s3_kms_key_arn == null
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.s3_kms_key_arn
        sse_algorithm     = var.s3_kms_key_arn == null ? "AES256" : "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_origin" {
  bucket = module.s3_site.s3_bucket_id
  policy = data.aws_iam_policy_document.cloudfront_s3_origin.json
}

data "aws_iam_policy_document" "cloudfront_s3_origin" {
  statement {
    sid    = "allow-cloudfront"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_site.s3_bucket_arn}/*"]
    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.site.arn]
      variable = "AWS:SourceArn"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = module.s3_site.s3_bucket_id

  rule {
    id     = "rule-1"
    status = "Enabled"
    transition {
      storage_class = "ONEZONE_IA"
      days          = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}