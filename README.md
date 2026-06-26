<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/raw/main/docs/logo-dark.png">
      <img src="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/raw/main/docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's Terraform AWS Cloudfront with S3 Origin Module</h3>

<p align="center">
    This is how I do it.
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues">Report Bug</a>
    .
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues">Request Feature</a>
  </p>
</p>

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/graphs/contributors)
[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues)
[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/pulls)
[<img alt="GitHub workflow: Terratest" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/test.yml?logo=githubactions&label=terratest">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/actions/workflows/test.yml)
[<img alt="GitHub workflow: Linting" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/lint.yml?logo=githubactions&label=linting">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/actions/workflows/lint.yml)
[<img alt="GitHub tag (with filter)" src="https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?filter=v*&label=latest%20tag&logo=terraform">](https://registry.terraform.io/modules/bendoerr-terraform-modules/cloudfront-with-s3-origin/aws/latest)
[<img alt="OSSF-Scorecard Score" src="https://img.shields.io/ossf-scorecard/github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=securityscorecard&label=ossf%20scorecard&link=https%3A%2F%2Fsecurityscorecards.dev%2Fviewer%2F%3Furi%3Dgithub.com%2Fbendoerr-terraform-modules%2Fterraform-aws-cloudfront-with-s3-origin">](https://securityscorecards.dev/viewer/?uri=github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin)
[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/blob/main/LICENSE.txt)

## About The Project

TODO

## Usage

TODO

## Security Headers

By default this module attaches AWS's `Managed-SecurityHeadersPolicy` as a
[CloudFront response headers policy](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/understanding-response-headers-policies.html)
on the distribution's default cache behavior. That sends the following HTTP
response headers on every viewer response:

- `Strict-Transport-Security: max-age=31536000`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `X-XSS-Protection: 0`

If you need different defaults — for example because your site must be framed
cross-origin, or you have a custom Content-Security-Policy — set
`security_headers = "custom"` and pass your own `response_headers_policy_id`,
or set `security_headers = "none"` to attach no policy at all.

```terraform
module "site" {
  source  = "bendoerr-terraform-modules/cloudfront-and-s3-origin/aws"
  # ...
  security_headers           = "custom"
  response_headers_policy_id = aws_cloudfront_response_headers_policy.mine.id
}
```

### Upgrade note

Earlier versions of this module did not attach any response headers policy.
Upgrading to a version that defaults `security_headers = "managed"` will start
sending `Strict-Transport-Security`, `X-Frame-Options: SAMEORIGIN`, and the
other headers listed above on viewer responses. If your site depends on not
receiving those (for example: embedded cross-origin in an iframe, or custom
HSTS settings managed elsewhere), set `security_headers = "custom"` or
`"none"` on upgrade.

## Version Constraints

This module uses **pessimistic version constraints** (`~>`) for its providers to
ensure predictable behavior across deployments:

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0" # Allows 6.x, prevents 7.0
  }
}
```

**Why pessimistic constraints?**

- Prevents unexpected breaking changes from major provider updates
- Ensures consistent behavior across environments
- Makes upgrade impact predictable and controllable

When AWS provider v7.0 releases, this module will require an update to support it.
That is intentional — we prefer explicit, tested upgrades over automatic major
version bumps.

For consuming this module, you can use any AWS provider version that satisfies both
your requirements and this module's constraints. Terraform's dependency resolver
will find a compatible version automatically.

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.0 |

### Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | ~> 6.0 |
| <a name="provider_aws.route53"></a> [aws.route53](#provider_aws.route53) | ~> 6.0 |

### Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_label_site"></a> [label_site](#module_label_site) | bendoerr-terraform-modules/label/null | 1.0.0 |
| <a name="module_s3_site"></a> [s3_site](#module_s3_site) | terraform-aws-modules/s3-bucket/aws | 5.14.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.site](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_route53_record.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket_lifecycle_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.cloudfront_s3_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_cloudfront_cache_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_iam_policy_document.cloudfront_s3_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input_context) | Shared Context from Ben's terraform-null-context | <pre>object({<br/>    attributes     = list(string)<br/>    dns_namespace  = string<br/>    environment    = string<br/>    instance       = string<br/>    instance_short = string<br/>    namespace      = string<br/>    region         = string<br/>    region_short   = string<br/>    role           = string<br/>    role_short     = string<br/>    project        = string<br/>    tags           = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_default_root_object"></a> [default_root_object](#input_default_root_object) | The default root object for the S3 bucket, typically used for web hosting. | `string` | `"index.html"` | no |
| <a name="input_domain_zone_id"></a> [domain_zone_id](#input_domain_zone_id) | If setting a custom CNAME for the Cloudfront distribution this is the Route 53 hosted zone ID. | `string` | n/a | yes |
| <a name="input_domain_zone_name"></a> [domain_zone_name](#input_domain_zone_name) | If setting a custom CNAME for the Cloudfront distribution this is the domain name for the zone. | `string` | n/a | yes |
| <a name="input_enable_spa_error_handling"></a> [enable_spa_error_handling](#input_enable_spa_error_handling) | Enable SPA error handling by redirecting 403 errors to / with 200 status code. | `bool` | `false` | no |
| <a name="input_extra_domain_prefixes"></a> [extra_domain_prefixes](#input_extra_domain_prefixes) | Prefixes for additional custom domains to be associated with the CloudFront distribution. Each prefix is concatenated as '<prefix>.\<domain_zone_name>' to form the final FQDN; multi-label prefixes (e.g. "api.cdn") are supported. | `list(string)` | `[]` | no |
| <a name="input_function_associations"></a> [function_associations](#input_function_associations) | A config block that triggers a lambda function with specific actions (maximum 4). | <pre>set(object({<br/>    event_type   = string<br/>    function_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input_name) | The name of the site, used for naming resources and identifiers. | `string` | `"site"` | no |
| <a name="input_response_headers_policy_id"></a> [response_headers_policy_id](#input_response_headers_policy_id) | CloudFront response headers policy ID. Required when var.security_headers = "custom"; ignored otherwise. | `string` | `null` | no |
| <a name="input_s3_kms_key_arn"></a> [s3_kms_key_arn](#input_s3_kms_key_arn) | The ARN of the KMS key used for S3 server-side encryption. | `string` | `null` | no |
| <a name="input_security_headers"></a> [security_headers](#input_security_headers) | Response headers policy strategy for the CloudFront distribution. One of: "managed" (attach AWS's Managed-SecurityHeadersPolicy — HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, X-XSS-Protection), "custom" (attach the policy at var.response_headers_policy_id — required when this is set), or "none" (no response headers policy attached). | `string` | `"managed"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudfront_distribution_alias_domain_name"></a> [cloudfront_distribution_alias_domain_name](#output_cloudfront_distribution_alias_domain_name) | The custom domain name generated by bendoerr-terraform-modules/terraform-null-label. |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront_distribution_arn](#output_cloudfront_distribution_arn) | The ARN of the CloudFront distribution. |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront_distribution_domain_name](#output_cloudfront_distribution_domain_name) | The domain name of the CloudFront distribution. |
| <a name="output_cloudfront_distribution_extra_domain_names"></a> [cloudfront_distribution_extra_domain_names](#output_cloudfront_distribution_extra_domain_names) | Any extra domain names provided. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront_distribution_id](#output_cloudfront_distribution_id) | The ID of the CloudFront distribution. |
| <a name="output_s3_bucket_arn"></a> [s3_bucket_arn](#output_s3_bucket_arn) | The ARN of the S3 bucket used for the site. |
| <a name="output_s3_bucket_id"></a> [s3_bucket_id](#output_s3_bucket_id) | The ID of the S3 bucket used for the site. |

<!-- END_TF_DOCS -->

## Roadmap

[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues)

See the
[open issues](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues)
for a list of proposed features (and known issues).

## Contributing

[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/pulls)

Contributions are what make the open source community such an amazing place to
be learn, inspire, and create. Any contributions you make are **greatly
appreciated**.

- If you have suggestions for adding or removing projects, feel free to
  [open an issue](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/issues/new)
  to discuss it, or directly create a pull request after you edit the
  _README.md_ file with necessary changes.
- Please make sure you check your spelling and grammar.
- Create individual PR for each suggestion.

### Creating A Pull Request

1. Fork the Project
1. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
1. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
1. Push to the Branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request

## License

[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/blob/main/LICENSE.txt)

Distributed under the MIT License. See
[LICENSE](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/blob/main/LICENSE.txt)
for more information.

## Authors

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-cloudfront-with-s3-origin/graphs/contributors)

- **Benjamin R. Doerr** - _Terraformer_ -
  [Benjamin R. Doerr](https://github.com/bendoerr/) - _Built Ben's Terraform
  Modules_

## Supported Versions

Only the latest tagged version is supported.

## Reporting a Vulnerability

See [SECURITY.md](SECURITY.md).

## Acknowledgements

- [ShaanCoding (ReadME Generator)](https://github.com/ShaanCoding/ReadME-Generator)
- [OpenSSF - Helping me follow best practices](https://openssf.org/)
- [StepSecurity - Helping me follow best practices](https://app.stepsecurity.io/)
- [Infracost - Better than AWS Calculator](https://www.infracost.io/)
