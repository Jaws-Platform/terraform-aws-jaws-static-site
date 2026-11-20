# terraform-aws-jaws-static-site

[![Terraform Registry](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fregistry.terraform.io%2Fv1%2Fmodules%2FJaws-Platform%2Fjaws-static-site%2Faws&query=%24.version&prefix=v&label=registry&logo=terraform&color=7B42BC)](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest)
[![GitHub release](https://img.shields.io/github/v/release/Jaws-Platform/terraform-aws-jaws-static-site?label=release)](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/releases/latest)
[![CI](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/actions/workflows/ci.yml/badge.svg?event=pull_request)](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/blob/main/LICENSE)

A static site on AWS with three environments served from one private S3
bucket: production, an optional dev site, and a preview of every pull request
at `pr-<n>.preview.<domain>`. Each environment is a CloudFront distribution
with its own certificate and DNS records, and the bucket is never public.

It is one of the [Jaws](https://github.com/jwallace145/jaws) module families,
and has no dependency on Jaws: everything is a plain input.

## What it creates

```text
 viewer                                      CloudFront                    S3 bucket (private)
                                                                          ┌──────────────────┐
 https://guitar.example.com ───────────────► production ────────────────► │ prod/            │
                                                                          │                  │
 https://dev.guitar.example.com ───────────► dev (optional) ────────────► │ dev/             │
                                                                          │                  │
 https://pr-42.preview.guitar.example.com ─► preview, one distribution ─► │ previews/pr-42/  │
 https://pr-57.preview.guitar.example.com ─► for every pull request ────► │ previews/pr-57/  │
                                                                          └──────────────────┘
```

The three environments are three prefixes of one bucket:

| Environment | URL | Served from | Created |
|---|---|---|---|
| Production | `https://<domain_name>` | `<bucket>/prod` | always |
| Dev | `https://<dev_domain_name>` | `<bucket>/dev` | when `dev_domain_name` is set |
| Pull request `n` | `https://pr-<n>.preview.<domain_name>` | `<bucket>/previews/pr-<n>` | unless `enable_preview = false` |

Each environment is one CloudFront distribution with a DNS-validated ACM
certificate, an origin access control that signs its requests to the bucket,
a viewer-request function, and `A` and `AAAA` alias records in the hosted
zone. The function serves `/docs/index.html` for `/docs/`; on the preview
distribution it also maps the `pr-<n>` label of the host name to its folder,
so one wildcard distribution serves every open pull request and nothing is
created per pull request.

The root module creates the distributions only. The bucket and the hosted
zone are inputs: create them with `site-bucket` and `hosted-zone`, in the
same configuration or in one applied earlier, or bring your own.

## Modules

| Module | Creates |
|---|---|
| [root](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest) | The site stack on an existing bucket and zone: `static-site` for production, `static-site` again for dev when `dev_domain_name` is set, and `preview-site` unless `enable_preview = false`. |
| [`static-site`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/static-site) | One environment: the ACM certificate, origin access control, CloudFront distribution, index-rewrite function and Route 53 aliases for `<domain>`, served from `<bucket>/<origin_path>`. |
| [`preview-site`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/preview-site) | Pull-request previews: a wildcard certificate and one distribution for `pr-<n>.preview.<domain>`, served from `<bucket>/previews/pr-<n>` with a short cache. |
| [`site-bucket`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/site-bucket) | The private, versioned, encrypted `<name_root>-<project>` bucket that holds every environment, with lifecycle rules and a bucket policy that admits CloudFront only; optionally hardened so that only named roles can write each prefix. |
| [`hosted-zone`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/hosted-zone) | A public Route 53 hosted zone with its zone-level CAA and TXT records. Never destroyed by Terraform. |

## Usage

The site stack on a bucket and a zone that already exist:

```hcl
provider "aws" {
  region = "us-east-1" # the only supported region
}

module "site" {
  source  = "Jaws-Platform/jaws-static-site/aws"
  version = "0.1.2" # x-release-please-version

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  domain_name                 = "guitar.example.com"
  dev_domain_name             = "dev.guitar.example.com" # optional
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}
```

The zone and the bucket created next to it:

```hcl
module "zone" {
  source  = "Jaws-Platform/jaws-static-site/aws//modules/hosted-zone"
  version = "0.1.2" # x-release-please-version

  name    = "example.com"
  comment = "Managed by Terraform in acme/guitar"
}

module "site_bucket" {
  source  = "Jaws-Platform/jaws-static-site/aws//modules/site-bucket"
  version = "0.1.2" # x-release-please-version

  name_root = "acme"
  project   = "guitar" # the bucket is acme-guitar
}

module "site" {
  source  = "Jaws-Platform/jaws-static-site/aws"
  version = "0.1.2" # x-release-please-version

  bucket_name                 = module.site_bucket.name
  bucket_regional_domain_name = module.site_bucket.regional_domain_name
  domain_name                 = "guitar.example.com"
  zone_id                     = module.zone.zone_id
}
```

Each submodule can also be used on its own, for example `static-site` for one
more environment on the same bucket:

```hcl
module "staging" {
  source  = "Jaws-Platform/jaws-static-site/aws//modules/static-site"
  version = "0.1.2" # x-release-please-version

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  origin_path                 = "/staging"
  domain_name                 = "staging.guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}
```

### Publishing

The modules upload nothing. Publishing an environment is copying the built
site under its prefix:

```sh
# Production (dev is the same, under dev/).
aws s3 sync ./dist "s3://acme-guitar/prod/" --delete
aws cloudfront create-invalidation --distribution-id "$PROD_DISTRIBUTION_ID" --paths '/*'

# The preview of one pull request. No invalidation: previews are cached for a minute.
aws s3 sync ./dist "s3://acme-guitar/previews/pr-${PR_NUMBER}/" --delete
```

The `distribution_ids` output has the distribution ID of each environment.

The IAM roles that let GitHub Actions do this without long-lived keys are a
separate family,
[`Jaws-Platform/jaws-ci/aws`](https://registry.terraform.io/modules/Jaws-Platform/jaws-ci/aws/latest):
[`ci-plan-role`](https://registry.terraform.io/modules/Jaws-Platform/jaws-ci/aws/latest/submodules/ci-plan-role)
plans the stack from a pull request,
[`ci-preview-role`](https://registry.terraform.io/modules/Jaws-Platform/jaws-ci/aws/latest/submodules/ci-preview-role)
can write `previews/` and nothing else, and
[`ci-apply-role`](https://registry.terraform.io/modules/Jaws-Platform/jaws-ci/aws/latest/submodules/ci-apply-role)
applies the stack and publishes `prod/` and `dev/`. Their permissions are the
`static-site/read`, `static-site/previews` and `static-site/deploy` policies
of
[`ci-policies`](https://registry.terraform.io/modules/Jaws-Platform/jaws-ci/aws/latest/submodules/ci-policies).
Those policies find a site's resources by the `Project` tag and by CloudFront
Function names that start with `<name_root>-<project>-`, which is what a
bucket named by `site-bucket` gives them. Nothing here depends on them: any
principal that can write a prefix can publish it.

## Examples

- [`basic`](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/tree/main/examples/basic):
  the site stack on a bucket and a zone that already exist.
- [`complete`](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/tree/main/examples/complete):
  the hosted zone, the site bucket and the site stack in one configuration.

## Cost

| | Per month, us-east-1 |
|---|---|
| Hosted zone | $0.50 |
| ACM certificates, origin access controls, alias records and the queries they answer | free |
| CloudFront distributions | nothing while idle. Data transfer out, requests and function invocations are billed by use, and the [CloudFront free tier](https://aws.amazon.com/cloudfront/pricing/) covers a small site |
| S3 | storage of the built site, usually a few cents: old object versions are kept for 30 days and previews for 14 |

A site with modest traffic costs about what its hosted zone does. Every
request runs the viewer-request function, so function invocations are the
first free allowance a busy site uses up.

## What to know before using it

- **`us-east-1` only.** CloudFront takes its certificates from ACM in
  `us-east-1` and nowhere else, so `static-site` and `preview-site` fail the
  plan in any other region. Configure the `aws` provider for `us-east-1`; a
  bucket created by `site-bucket` in the same configuration is then there
  too. Viewers are still served from CloudFront's edge locations.
- **The domain must already be delegated to the hosted zone.** Certificates
  are validated through records in the zone, and the apply waits for ACM to
  see them. With a zone that the registrar does not point at yet, it waits
  until it times out. Any CAA record on the domain must allow Amazon's
  certificate authorities; `hosted-zone` adds one that does.
- **Existing records are taken over.** The alias and validation records are
  written with `allow_overwrite`, so an `A` or `AAAA` record that already
  exists for `domain_name`, `dev_domain_name` or `*.preview.<domain_name>` is
  replaced without a plan-time error.
- **The bucket must let CloudFront read it.** `site-bucket` allows
  `s3:GetObject` to the CloudFront service for the whole account
  (`AWS:SourceAccount`), not for one distribution. Nothing else can read the
  bucket without IAM permissions, and the content is public through
  CloudFront anyway.
- **Production and dev are cached at the edge**, for a day by default (the
  managed `CachingOptimized` policy): invalidate after publishing. Previews
  are cached for 60 seconds, 5 minutes at most.
- **Directory indexes only.** `/docs/` and `/docs` are served from
  `/docs/index.html`; a path with a dot in it is requested as it is.
  Anything missing answers with `/404.html` and status 404, so the built
  site needs a `404.html` at its root, and there is no single-page-application
  fallback to `/index.html`.
- **Previews are public and short-lived.** Anyone with the URL can read a
  preview. Only `pr-<digits>` host names are served, and with `site-bucket`
  objects under `previews/` expire 14 days after they were written.
- **Fixed distribution settings.** HTTPS only (HTTP redirects), TLS 1.2 or
  newer, HTTP/2 and HTTP/3, IPv6, the managed `SecurityHeadersPolicy`, and
  `PriceClass_100` (edge locations in North America and Europe). No WAF, no
  access logs, no geographic restriction.
- **One site per bucket.** Function, origin access control and cache policy
  names are derived from the bucket name, so a second site stack on the same
  bucket collides with the first.
- **Terraform never destroys the hosted zone.** `hosted-zone` sets
  `prevent_destroy`: deleting a zone drops every record in it and changes its
  name servers.
- **Providers are never configured here.** The caller configures `aws`.
- **Tags.** Every resource that can be tagged gets `Component` from its
  module. Every other tag comes from the caller's provider `default_tags`;
  the modules take no tag map. The `jaws-ci` policies authorise by the
  `Project` tag, so set it there if you use them. The
  [`context`](https://registry.terraform.io/modules/Jaws-Platform/jaws-foundation/aws/latest/submodules/context)
  module of `Jaws-Platform/jaws-foundation/aws` derives such a tag set, and
  the same `<name_root>-<project>` bucket name, from a project's name.

The submodule READMEs have the details: what each distribution is made of,
the bucket's prefix layout and hardened policy, and how to adopt an existing
hosted zone.

## Development

See [CONTRIBUTING.md](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/blob/main/CONTRIBUTING.md)
for local setup, the commit and pull request rules, CI, and how releases work.
`scripts/check.sh` runs everything CI runs, with no AWS credentials.

## Root module reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11 |
| aws | ~> 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| dev | ./modules/static-site | n/a |
| preview | ./modules/preview-site | n/a |
| prod | ./modules/static-site | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bucket\_name | Name of the site bucket (output `name` of `site-bucket`). Production is served from its `prod/` prefix, dev from `dev/` and previews from `previews/pr-<n>/`. | `string` | n/a | yes |
| bucket\_regional\_domain\_name | Regional domain name of the site bucket (output `regional_domain_name` of `site-bucket`). | `string` | n/a | yes |
| domain\_name | Production FQDN, for example `guitar.example.com`. Served from `<bucket>/prod`; previews are served from `pr-<n>.preview.<domain_name>`. | `string` | n/a | yes |
| zone\_id | Route 53 hosted zone ID that contains `domain_name` (and `dev_domain_name`). | `string` | n/a | yes |
| dev\_domain\_name | Optional FQDN for the dev environment, served from `<bucket>/dev` (for example `dev.guitar.example.com`). Set to `null` to skip the dev distribution. | `string` | `null` | no |
| enable\_preview | Whether to create the `*.preview.<domain_name>` distribution for pull-request previews. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| dev\_distribution\_id | CloudFront distribution ID for the dev site, or `null` when `dev_domain_name` is not set. |
| dev\_url | Dev URL (`https://<dev_domain_name>`), or `null` when `dev_domain_name` is not set. |
| distribution\_ids | Map of environment name (`prod`, `dev`, `preview`) to CloudFront distribution ID, for invalidation scripts. |
| preview\_distribution\_id | CloudFront distribution ID for `*.preview.<domain_name>`, or `null` when `enable_preview` is false. |
| preview\_url\_pattern | Preview URL pattern (`https://pr-<n>.preview.<domain_name>`), or `null` when `enable_preview` is false. |
| prod\_distribution\_arn | CloudFront distribution ARN for the production site. |
| prod\_distribution\_id | CloudFront distribution ID for the production site. |
| prod\_url | Production URL (`https://<domain_name>`). |
<!-- END_TF_DOCS -->

## License

[MIT](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/blob/main/LICENSE)
