locals {
  # Modules take no tag map. Every resource inherits these through the
  # provider's default_tags, and each module adds `Component` (and `Name`).
  tags = {
    Organization = "acme"
    Project      = "guitar"
    Environment  = "preview"
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

module "preview_site" {
  source = "../../"

  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  site_domain                 = "guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}

output "distribution_id" {
  value = module.preview_site.distribution_id
}

output "url_pattern" {
  value = module.preview_site.url_pattern
}
