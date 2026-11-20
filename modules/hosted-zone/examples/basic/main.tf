locals {
  # Modules take no tag map. Every resource inherits these through the
  # provider's default_tags, and each module adds `Component` (and `Name`).
  tags = {
    Organization = "acme"
    Project      = "infra"
    Environment  = "prod"
    Repository   = "acme/acme-infra"
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

module "zone" {
  source = "../../"

  name    = "example.com"
  comment = "Zone managed by acme/acme-infra; each site's stack manages its own records"

  # The four Amazon CAs ACM needs, plus Let's Encrypt for sites still served
  # by GitHub Pages.
  caa_issuers = ["amazon.com", "amazontrust.com", "awstrust.com", "amazonaws.com", "letsencrypt.org"]

  # Keep the Name tag the zone already carries.
  name_tag = "acme-infra-dns-zone"

  # GitHub Pages domain verification for the GitHub account that owns the
  # domain. The record name carries the account's username and the token
  # comes from https://github.com/settings/pages; pass it bare, the provider
  # adds the quotes.
  txt_records = {
    "_github-pages-challenge-octocat" = ["0123456789abcdef0123456789abcd"]
  }
}

output "zone_id" {
  value = module.zone.zone_id
}

output "name_servers" {
  value = module.zone.name_servers
}
