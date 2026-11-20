# Root module: the full static-site stack a project repository deploys.
#
#   prod     https://<domain_name>              <- <bucket>/prod
#   dev      https://<dev_domain_name>          <- <bucket>/dev      (optional)
#   preview  https://pr-<n>.preview.<domain>    <- <bucket>/previews/pr-<n>
#
# This module only consumes the bucket and the hosted zone: create them with
# the `site-bucket` and `hosted-zone` submodules, or bring your own. Every
# submodule can also be used on its own.

module "prod" {
  source = "./modules/static-site"

  bucket_name                 = var.bucket_name
  bucket_regional_domain_name = var.bucket_regional_domain_name
  origin_path                 = "/prod"
  domain_name                 = var.domain_name
  zone_id                     = var.zone_id
}

module "dev" {
  source = "./modules/static-site"
  count  = var.dev_domain_name == null ? 0 : 1

  bucket_name                 = var.bucket_name
  bucket_regional_domain_name = var.bucket_regional_domain_name
  origin_path                 = "/dev"
  domain_name                 = var.dev_domain_name
  zone_id                     = var.zone_id
}

module "preview" {
  source = "./modules/preview-site"
  count  = var.enable_preview ? 1 : 0

  bucket_name                 = var.bucket_name
  bucket_regional_domain_name = var.bucket_regional_domain_name
  site_domain                 = var.domain_name
  zone_id                     = var.zone_id
}
