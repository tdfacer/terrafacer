# variables

## global

variable "app_name" {
  type        = string
  description = "the name of the static site app"
}

## s3

variable "bucket_name" {
  type        = string
  description = "the name of the s3 bucket to store the static site in"
}

## dns

variable "domain_name" {
  type        = string
  description = "the domain name that should be used to point to the static site"
}

variable "zone_id" {
  type        = string
  description = "the hosted zone ID for the domain"
}

## acm

variable "acm_certificate_arn" {
  type        = string
  description = "the acm certificate that CloudFront should use for the static site"
}

data "aws_iam_policy_document" "web_distribution" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
    resources = [format("%s/*", module.s3_bucket.s3_bucket_arn)]
  }
}

resource "aws_s3_bucket_policy" "web_distribution" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.web_distribution.json
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = var.bucket_name
  force_destroy = true

  versioning = {
    enabled = true
  }

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  tags = {
    app_name = var.app_name
  }
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.1"
  depends_on = [
    module.s3_bucket
  ]

  enabled             = true
  retain_on_delete    = false
  wait_for_deployment = true # modified from false to ensure the distro deploys properly

  comment = format("CloudFront distribution for %s static site", var.domain_name)
  aliases = [var.domain_name]

  default_cache_behavior = {
    target_origin_id       = "website"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  default_root_object = "index.html"
  is_ipv6_enabled     = true

  origin = {
    website = {
      domain_name = replace(module.s3_bucket.s3_bucket_website_endpoint, "-website-", ".")
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
  }

  price_class = "PriceClass_100"

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = format("%s access for %s", var.bucket_name, var.app_name)
  }

  viewer_certificate = {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    app_name = var.app_name
  }
}

resource "aws_route53_record" "dns" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_distribution_domain_name
    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

# iam user

resource "aws_iam_user" "user" {
  name = var.app_name
  path = "/"

  tags = {
    app = var.app_name
  }
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy" "user_policy" {
  name = format("%s-policy", var.app_name)
  user = aws_iam_user.user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${module.s3_bucket.s3_bucket_arn}/*"
    }
  ]
}
EOF
}
