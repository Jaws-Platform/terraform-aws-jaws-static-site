# static-site

Part of [`jaws-platform/jaws-static-site/aws`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest) · [Registry](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/static-site) · [Source](https://github.com/jaws-platform/terraform-aws-jaws-static-site/tree/main/modules/static-site)

Serves one environment of a static site from a prefix of a private S3 bucket
through CloudFront. Call it once per environment (`prod`, `dev`, ...), each
with its own `origin_path` and `domain_name`. The
[root module](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest)
does that for a production, a dev and a pull-request preview environment in
one call.

## What it creates

- An ACM certificate for `domain_name`, validated through Route 53 DNS.
- A CloudFront origin access control (OAC) for the S3 origin.
- A CloudFront distribution that:
  - serves `bucket_regional_domain_name` at `origin_path` (for example `/prod`)
  - redirects HTTP to HTTPS, requires `TLSv1.2_2021`, enables HTTP/2 and HTTP/3
  - uses the managed `CachingOptimized` cache policy and the managed
    `SecurityHeadersPolicy` response headers policy
  - serves `/404.html` with status 404 for missing objects. S3 returns 403 for
    missing keys when the viewer only has `GetObject`, so both 403 and 404 are
    mapped to the custom error page.
- A viewer-request CloudFront Function that rewrites `/dir/` to
  `/dir/index.html` (and `/dir` without an extension to `/dir/index.html`).
- Route 53 `A` and `AAAA` alias records for `domain_name`.

Everything runs in `us-east-1`; the module has a precondition that fails the
plan in any other region.

Every resource is tagged `Component = "static-site"`. All other tags come from
the caller's provider `default_tags`.

The bucket and the hosted zone are inputs. The bucket's policy must let
CloudFront read it:
[`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket)
creates one that does.

The CloudFront Function is named `<bucket_name>-<domain-with-dashes>`,
truncated to 64 characters.

The module creates no IAM, and any principal with the permissions can apply
it. The CI roles of
[`jaws-platform/jaws-ci/aws`](https://registry.terraform.io/modules/jaws-platform/jaws-ci/aws/latest)
are made for it: the `static-site/*` policies of
[`ci-policies`](https://registry.terraform.io/modules/jaws-platform/jaws-ci/aws/latest/submodules/ci-policies)
authorise changes to these resources by the `Project` tag they inherit from
`default_tags`, and to the function by its name, which falls in their
`<name_root>-<project>-*` scope when the bucket is named
`<name_root>-<project>`, as `site-bucket` names it.

## Usage

```hcl
provider "aws" {
  region = "us-east-1" # the only supported region
}

module "prod" {
  source  = "jaws-platform/jaws-static-site/aws//modules/static-site"
  version = "0.1.0" # x-release-please-version

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  origin_path                 = "/prod"
  domain_name                 = "guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}
```

With the bucket and the zone in the same configuration, pass the outputs of
[`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket)
and
[`hosted-zone`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/hosted-zone)
instead: `module.site_bucket.name`, `module.site_bucket.regional_domain_name`
and `module.zone.zone_id`.

Publishing is copying the built site under the prefix, then invalidating the
distribution, which caches for a day by default:

```sh
aws s3 sync ./dist "s3://acme-guitar/prod/" --delete
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths '/*'
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11 |
| aws | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.viewer_request](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_route53_record.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_cloudfront_cache_policy.caching_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_response_headers_policy.security_headers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bucket\_name | Name of the site bucket (output `name` of `site-bucket`). Also used as the prefix of the CloudFront Function name. | `string` | n/a | yes |
| bucket\_regional\_domain\_name | Regional domain name of the site bucket (output `regional_domain_name` of `site-bucket`), used as the distribution origin. | `string` | n/a | yes |
| domain\_name | FQDN the site is served on, for example `guitar.example.com`. An ACM certificate is issued for exactly this name. | `string` | n/a | yes |
| origin\_path | Prefix inside the bucket this environment is served from, for example `/prod` or `/dev`. Must start with `/` and not end with one. | `string` | n/a | yes |
| zone\_id | Route 53 hosted zone ID that contains `domain_name`. Validation and alias records are created in it. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| distribution\_arn | CloudFront distribution ARN. |
| distribution\_id | CloudFront distribution ID (use for `aws cloudfront create-invalidation`). |
| url | Public URL of the site (`https://<domain_name>`). |
<!-- END_TF_DOCS -->
