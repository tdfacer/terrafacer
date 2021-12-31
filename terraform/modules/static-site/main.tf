variable "app_name" {
  type        = string
  description = "the name of the static site app"
}

variable "bucket_name" {
  type        = string
  description = "the name of the s3 bucket to store the static site in"
}

variable "domain_name" {
  type        = string
  description = "the domain name that should be used to point to the static site"
}

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
    resources = [format("%s/*"), module.s3_bucket.s3_bucket_arn]
  }
}

resource "aws_s3_bucket_policy" "web_distribution" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.web_distribution.json
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true

  # attach_policy = true
  # policy        = data.aws_iam_policy_document.bucket_policy.json

  versioning = {
    enabled = true
  }

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls = true
  # block_public_policy = true
  # ignore_public_acls      = true
  # restrict_public_buckets = true

  # S3 Bucket Ownership Controls
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
    target_origin_id       = format("s3-%s-static-site", var.app_name)
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
      domain_name = module.s3_bucket.s3_bucket_arn.s3_bucket_website_domain
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
