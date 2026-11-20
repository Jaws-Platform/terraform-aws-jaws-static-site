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

module "site_bucket" {
  source = "../../"

  name_root = "acme"
  project   = "guitar"
}

output "bucket_name" {
  value = module.site_bucket.name
}

output "bucket_arn" {
  value = module.site_bucket.arn
}

output "bucket_regional_domain_name" {
  value = module.site_bucket.regional_domain_name
}
