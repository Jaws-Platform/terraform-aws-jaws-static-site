provider "aws" {
  # CloudFront takes its certificates from us-east-1 only, and the site
  # modules refuse to plan anywhere else.
  region = "us-east-1"

  # The modules take no tag map. Every resource inherits these, and each
  # module adds `Component`.
  default_tags {
    tags = {
      Project     = "guitar"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# The zone the site's names live in, with a CAA record that lets ACM issue
# certificates. Delegate the domain to `name_servers` at its registrar before
# the site is applied: the certificates are validated through this zone.
module "zone" {
  source = "../../modules/hosted-zone"

  name    = "example.com"
  comment = "Managed by Terraform in acme/guitar"
}

# One private bucket for every environment of the site: acme-guitar.
module "site_bucket" {
  source = "../../modules/site-bucket"

  name_root = "acme"
  project   = "guitar"
}

# Three distributions on that bucket:
#
#   https://guitar.example.com                 <- acme-guitar/prod
#   https://dev.guitar.example.com             <- acme-guitar/dev
#   https://pr-<n>.preview.guitar.example.com  <- acme-guitar/previews/pr-<n>
module "site" {
  source = "../../"

  bucket_name                 = module.site_bucket.name
  bucket_regional_domain_name = module.site_bucket.regional_domain_name
  domain_name                 = "guitar.example.com"
  dev_domain_name             = "dev.guitar.example.com"
  zone_id                     = module.zone.zone_id
}

output "name_servers" {
  description = "Name servers to set for the domain at its registrar."
  value       = module.zone.name_servers
}

output "bucket_name" {
  description = "The bucket to publish to, under prod/, dev/ and previews/pr-<n>/."
  value       = module.site_bucket.name
}

output "urls" {
  description = "URL of each environment."
  value = {
    prod    = module.site.prod_url
    dev     = module.site.dev_url
    preview = module.site.preview_url_pattern
  }
}

output "distribution_ids" {
  description = "Distribution ID of each environment, for invalidations after publishing."
  value       = module.site.distribution_ids
}
