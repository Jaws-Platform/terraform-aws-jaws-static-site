# The root's outputs with every environment switched on, and the input
# validations that site_stack.tftest.hcl does not exercise.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
      domain_validation_options = [{
        domain_name           = "validation"
        resource_record_name  = "_abc.guitar.example.com."
        resource_record_type  = "CNAME"
        resource_record_value = "_def.acm-validations.aws."
      }]
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      id             = "E1234567890ABC"
      arn            = "arn:aws:cloudfront::123456789012:distribution/E1234567890ABC"
      domain_name    = "d111111abcdef8.cloudfront.net"
      hosted_zone_id = "Z2FDTNDATAQYW2"
    }
  }
}

variables {
  bucket_name                 = "acme-guitar"
  bucket_regional_domain_name = "acme-guitar.s3.us-east-1.amazonaws.com"
  domain_name                 = "guitar.example.com"
  zone_id                     = "Z0123456789ABCDEFGHIJ"
}

run "outputs_with_every_environment" {
  command = plan

  variables {
    dev_domain_name = "dev.guitar.example.com"
  }

  assert {
    condition     = output.prod_distribution_id == "E1234567890ABC" && output.prod_distribution_arn == "arn:aws:cloudfront::123456789012:distribution/E1234567890ABC"
    error_message = "the prod outputs must come from the production distribution"
  }

  assert {
    condition     = output.dev_distribution_id == "E1234567890ABC" && output.preview_distribution_id == "E1234567890ABC"
    error_message = "the dev and preview distribution IDs must be set when both environments exist"
  }

  assert {
    condition = output.distribution_ids == {
      dev     = "E1234567890ABC"
      preview = "E1234567890ABC"
      prod    = "E1234567890ABC"
    }
    error_message = "distribution_ids must map every environment to its distribution"
  }

  assert {
    condition = (
      output.prod_url == "https://guitar.example.com" &&
      output.dev_url == "https://dev.guitar.example.com" &&
      output.preview_url_pattern == "https://pr-<n>.preview.guitar.example.com"
    )
    error_message = "the URLs must follow domain_name and dev_domain_name"
  }
}

run "prod_alone" {
  command = plan

  variables {
    enable_preview = false
  }

  assert {
    condition     = length(module.dev) == 0 && length(module.preview) == 0 && keys(output.distribution_ids) == ["prod"]
    error_message = "without dev_domain_name and with enable_preview = false only production is created"
  }
}

run "rejects_bad_bucket_name" {
  command = plan

  variables {
    bucket_name = "Acme_Guitar"
  }

  expect_failures = [var.bucket_name]
}

run "rejects_a_website_endpoint_as_bucket_domain" {
  command = plan

  variables {
    # The origin has to be the bucket's REST endpoint: origin access control
    # does not work with the website endpoint.
    bucket_regional_domain_name = "acme-guitar.s3-website-us-east-1.amazonaws.com"
  }

  expect_failures = [var.bucket_regional_domain_name]
}

run "rejects_bad_domain_name" {
  command = plan

  variables {
    domain_name = "Guitar.Example.Com."
  }

  expect_failures = [var.domain_name]
}

run "rejects_bad_zone_id" {
  command = plan

  variables {
    zone_id = "example.com"
  }

  expect_failures = [var.zone_id]
}
