# hosted-zone

Part of [`Jaws-Platform/jaws-static-site/aws`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest) · [Registry](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/hosted-zone) · [Source](https://github.com/Jaws-Platform/terraform-aws-jaws-static-site/tree/main/modules/hosted-zone)

A public Route 53 hosted zone and its zone-level records: a CAA record and
any TXT records the zone owner holds. It is typically applied once per
domain. The stacks of the sites served under the domain create their own
records inside it, as
[`static-site`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/static-site)
and
[`preview-site`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest/submodules/preview-site)
do. Use `comment` to say who owns what, because the comment is what someone
sees first in the console.

- The zone is tagged `Name` and `Component`. `Name` is the zone name unless
  `name_tag` is set.
- When `caa_issuers` is not empty, the module creates one CAA record at the
  zone apex with a `0 issue "<issuer>"` value per issuer. The default is the
  four Amazon CAs that ACM needs. An empty list creates no CAA record.
- `txt_records` creates one TXT record per entry for the tokens that belong
  to the zone owner rather than to a project: GitHub Pages domain
  verification (`_github-pages-challenge-<user>`), SPF, site verification.
  Keys are record names relative to the zone, `@` for the apex. Pass bare
  strings: the AWS provider wraps each TXT string in the double quotes Route
  53 wants (and strips them on read), so quoting them yourself doubles the
  quotes and Route 53 rejects the record. Verification tokens stay valid only
  while the record exists, so keep them here rather than adding them by hand.

## `prevent_destroy` is hard-coded

The zone carries `lifecycle { prevent_destroy = true }`. Terraform does not
allow lifecycle arguments to come from variables, so this cannot be turned
off by an input. Deleting a zone removes every record in it, and a recreated
zone gets new name servers that the registrar does not know about. To remove
the zone on purpose, remove it from state first.

## Adopting an existing zone

To bring a zone that is already in state under this module, add `moved`
blocks to the module's addresses and pass the zone's current `Name` tag as
`name_tag`:

```hcl
moved {
  from = aws_route53_zone.this
  to   = module.zone.aws_route53_zone.this
}

moved {
  from = aws_route53_record.caa
  to   = module.zone.aws_route53_record.caa[0]
}
```

To adopt a zone that is not in any state yet, import it to
`module.zone.aws_route53_zone.this`.

## Usage

```hcl
module "zone" {
  source  = "Jaws-Platform/jaws-static-site/aws//modules/hosted-zone"
  version = "0.1.1" # x-release-please-version

  name    = "example.com"
  comment = "Zone managed by acme/acme-infra; each site's stack manages its own records"

  txt_records = {
    "_github-pages-challenge-octocat" = ["0123456789abcdef0123456789abcd"]
  }
}
```

After the first apply, set `name_servers` at the domain's registrar.
`zone_id` is the `zone_id` input of `static-site`, `preview-site` and the
[root module](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest).
Their certificates are validated through records in this zone, so delegate
the domain before applying them.

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
| [aws_route53_record.caa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.txt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| comment | Zone comment. State who owns the zone and who owns its records, for example `Zone managed by acme/acme-infra; each site's stack manages its own records`. | `string` | n/a | yes |
| name | Zone name as a lowercase FQDN without a trailing dot, for example `example.com`. | `string` | n/a | yes |
| caa\_issuers | Certificate authorities allowed to issue for the zone and its subdomains, as CAA `issue` domains. The default is the four Amazon CAs that ACM needs. An empty list creates no CAA record. | `list(string)` | <pre>[<br/>  "amazon.com",<br/>  "amazontrust.com",<br/>  "awstrust.com",<br/>  "amazonaws.com"<br/>]</pre> | no |
| caa\_ttl | TTL in seconds of the CAA record. | `number` | `300` | no |
| component | Value of the `Component` tag on the zone. | `string` | `"dns"` | no |
| name\_tag | Value of the zone's `Name` tag. Left `null`, it falls back to `name`. Set it to an existing zone's current `Name` tag to adopt the zone without a tag change. | `string` | `null` | no |
| txt\_records | Zone-level TXT records that belong to the zone owner rather than to a project, such as domain-verification tokens (`_github-pages-challenge-<user>`) or SPF. Keyed by the record name relative to the zone (`@` for the apex); each value is the list of strings for that record. Pass bare strings; the AWS provider adds the quotes Route 53 wants. | `map(list(string))` | `{}` | no |
| txt\_ttl | TTL in seconds of the TXT records. | `number` | `300` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| arn | Hosted zone ARN, for IAM policies, for example `policy_inputs.foundation.hosted_zone_arn` of the CI role modules in `Jaws-Platform/jaws-ci/aws`. |
| name | Zone name. |
| name\_servers | Name servers to delegate the domain to at its registrar. |
| zone\_id | Hosted zone ID: the `zone_id` input of `static-site`, `preview-site` and the root site stack, and `policy_inputs.static_site.zone_id` of the CI role modules in `Jaws-Platform/jaws-ci/aws`. |
<!-- END_TF_DOCS -->
