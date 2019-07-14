resource "aws_dynamodb_table" "table" {
  name           = "BucketItems"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    Name = var.resource_prefix
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.resource_prefix}-images"
  acl    = "private"

  tags = {
    Name = var.resource_prefix
  }
}
