locals {
  # Modules take no tag map. Every resource inherits these through the
  # provider's default_tags, and each module adds `Component` (and `Name`).
  tags = {
    Organization = "acme"
    Project      = "guitar"
    Environment  = "prod"
    Repository   = "acme/guitar"
    ManagedBy    = "terraform"
    Owner        = "platform-team"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

# The bucket and the hosted zone already exist and are named by literal
# values, as when another configuration owns them. `../complete` creates
# them next to the site instead.
module "site" {
  source = "../../"

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  domain_name                 = "guitar.example.com"
  dev_domain_name             = "dev.guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
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
