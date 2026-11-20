# Basic: the site stack on an existing bucket and zone

The three environments of `guitar.example.com`, served from a bucket and a
hosted zone that already exist:

| Environment | URL | Served from |
|---|---|---|
| Production | `https://guitar.example.com` | `s3://acme-guitar/prod/` |
| Dev | `https://dev.guitar.example.com` | `s3://acme-guitar/dev/` |
| Pull request `n` | `https://pr-<n>.preview.guitar.example.com` | `s3://acme-guitar/previews/pr-<n>/` |

The bucket and the zone are named by literal values, which is how the stack
looks when another configuration owns them. The bucket's policy has to let
CloudFront read it; the
[`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket)
submodule creates one that does. The
[`complete`](https://github.com/jaws-platform/terraform-aws-jaws-static-site/tree/main/examples/complete)
example creates the bucket and the zone next to the site instead.

```sh
terraform init
terraform plan
```

In your own configuration, replace the relative `source` with the registry
address:

```hcl
module "site" {
  source  = "jaws-platform/jaws-static-site/aws"
  version = "0.1.0" # x-release-please-version

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  domain_name                 = "guitar.example.com"
  dev_domain_name             = "dev.guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}
```
