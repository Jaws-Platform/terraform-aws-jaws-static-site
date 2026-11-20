# Complete: the hosted zone, the site bucket and the site stack

Everything a static site needs, in one configuration:

- a public hosted zone for `example.com`, with a CAA record that lets ACM
  issue certificates
  ([`hosted-zone`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/hosted-zone));
- the private bucket `acme-guitar` that holds every environment
  ([`site-bucket`](https://registry.terraform.io/modules/jaws-platform/jaws-static-site/aws/latest/submodules/site-bucket));
- the site stack on both (the root module): production at
  `guitar.example.com`, dev at `dev.guitar.example.com` and pull-request
  previews at `pr-<n>.preview.guitar.example.com`, served from the bucket's
  `prod/`, `dev/` and `previews/pr-<n>/` prefixes.

The outputs of the first two are the inputs of the third: the bucket's `name`
and `regional_domain_name`, and the zone's `zone_id`.

```sh
terraform init
terraform plan
```

The certificates are validated through records in the zone, so the domain
has to be delegated to the zone before the distributions can be created. On
a first apply, create the zone on its own
(`terraform apply -target=module.zone`), set the name servers from the
`name_servers` output at the domain's registrar, then apply the rest.
`terraform destroy` stops at the zone, which carries `prevent_destroy`.

Publishing the site is a separate step: see
[Publishing](https://github.com/jaws-platform/terraform-aws-jaws-static-site#publishing)
in the main README.

In your own configuration, replace the relative sources with the registry
addresses:

```hcl
module "zone" {
  source  = "jaws-platform/jaws-static-site/aws//modules/hosted-zone"
  version = "0.1.1" # x-release-please-version

  name    = "example.com"
  comment = "Managed by Terraform in acme/guitar"
}

module "site_bucket" {
  source  = "jaws-platform/jaws-static-site/aws//modules/site-bucket"
  version = "0.1.1" # x-release-please-version

  name_root = "acme"
  project   = "guitar"
}

module "site" {
  source  = "jaws-platform/jaws-static-site/aws"
  version = "0.1.1" # x-release-please-version

  bucket_name                 = module.site_bucket.name
  bucket_regional_domain_name = module.site_bucket.regional_domain_name
  domain_name                 = "guitar.example.com"
  dev_domain_name             = "dev.guitar.example.com"
  zone_id                     = module.zone.zone_id
}
```
