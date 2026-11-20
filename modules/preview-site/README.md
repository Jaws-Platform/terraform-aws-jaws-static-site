# preview-site

Part of [`jaws-platform/jaws-static-site/aws`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest) · [Registry](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/preview-site) · [Source](https://github.com/jaws-platform/terraform-aws-jaws-static-site/tree/main/modules/preview-site)

Serves pull-request previews of a static site from `pr-<n>.preview.<site_domain>`.
Call it once per site: a pull request workflow uploads each PR's build to
`previews/pr-<n>/` in the site bucket, and this one distribution routes the
matching subdomain to it. Nothing is created per pull request.

## What it creates

- A wildcard ACM certificate for `*.preview.<site_domain>`, DNS-validated.
- A CloudFront origin access control for the S3 origin.
- A custom cache policy with low TTLs (min 0s, default 60s, max 300s) so new
  pushes show up quickly without invalidations.
- A CloudFront distribution aliased to `*.preview.<site_domain>` with origin
  path `/previews`, HTTP to HTTPS redirect, `TLSv1.2_2021`, HTTP/2 and HTTP/3,
  the managed security-headers policy and `/404.html` for 403/404.
- A viewer-request CloudFront Function that:
  1. extracts the first label of the `Host` header
  2. returns `404` unless that label matches `^pr-\d+$`
  3. otherwise rewrites the URI to `/<label><uri>`, applying the same
     `index.html` rewrite as `static-site` (`/dir/` and `/dir` become
     `/dir/index.html`)
- Wildcard Route 53 `A` and `AAAA` alias records for `*.preview.<site_domain>`.

Everything runs in `us-east-1`; the module has a precondition that fails the
plan in any other region.

Every resource is tagged `Component = "preview-site"`. All other tags come from
the caller's provider `default_tags`.

The function is named `<bucket_name>-preview` and the cache policy
`<bucket_name>-preview-low-ttl`, so a bucket carries one preview
distribution. With a bucket named `<name_root>-<project>`, as
[`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket)
names it, the function name falls in the `<name_root>-<project>-*` scope of
the `static-site/*` policies in
[`ci-policies`](https://registry.terraform.io/modules/jaws-platform/jaws-ci/aws/latest/submodules/ci-policies),
for sites that are deployed by the CI roles of
[`jaws-platform/jaws-ci/aws`](https://registry.terraform.io/modules/jaws-platform/jaws-ci/aws/latest).

## Usage

```hcl
module "preview" {
  source  = "jaws-platform/jaws-static-site/aws//modules/preview-site"
  version = "0.1.1" # x-release-please-version

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  site_domain                 = "guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}
```

A pull request workflow then publishes its build. A role from
[`ci-preview-role`](https://registry.terraform.io/modules/jaws-platform/jaws-ci/aws/latest/submodules/ci-preview-role)
with the `static-site/previews` policy can write under `previews/` and
nowhere else in the bucket:

```sh
aws s3 sync ./dist "s3://acme-guitar/previews/pr-${PR_NUMBER}/" --delete
echo "https://pr-${PR_NUMBER}.preview.guitar.example.com"
```

Objects under `previews/` expire after 14 days when the bucket comes from
[`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket).

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
| [aws_cloudfront_cache_policy.low_ttl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.viewer_request](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_route53_record.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_cloudfront_response_headers_policy.security_headers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bucket\_name | Name of the site bucket (output `name` of `site-bucket`). Also used as the prefix of the CloudFront Function name. | `string` | n/a | yes |
| bucket\_regional\_domain\_name | Regional domain name of the site bucket (output `regional_domain_name` of `site-bucket`), used as the distribution origin. | `string` | n/a | yes |
| site\_domain | The site's production FQDN, for example `guitar.example.com`. Previews are served from `pr-<n>.preview.<site_domain>`. | `string` | n/a | yes |
| zone\_id | Route 53 hosted zone ID that contains `site_domain`. Validation and wildcard alias records are created in it. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| distribution\_id | CloudFront distribution ID serving `*.preview.<site_domain>`. |
| url\_pattern | URL pattern for previews: `https://pr-<n>.preview.<site_domain>`. |
<!-- END_TF_DOCS -->
