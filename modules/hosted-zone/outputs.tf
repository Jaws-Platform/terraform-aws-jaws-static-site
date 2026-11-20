output "zone_id" {
  description = "Hosted zone ID: the `zone_id` input of `static-site`, `preview-site` and the root site stack, and `policy_inputs.static_site.zone_id` of the CI role modules in `Jaws-Platform/jaws-ci/aws`."
  value       = aws_route53_zone.this.zone_id
}

output "arn" {
  description = "Hosted zone ARN, for IAM policies, for example `policy_inputs.foundation.hosted_zone_arn` of the CI role modules in `Jaws-Platform/jaws-ci/aws`."
  value       = aws_route53_zone.this.arn
}

output "name" {
  description = "Zone name."
  value       = aws_route53_zone.this.name
}

output "name_servers" {
  description = "Name servers to delegate the domain to at its registrar."
  value       = aws_route53_zone.this.name_servers
}
