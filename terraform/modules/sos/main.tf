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

resource "aws_iam_user" "user" {
  name = "sos"
  path = "/"

  tags = {
    Name = var.resource_prefix
  }
}

resource "aws_iam_access_key" "key" {
  user = "${aws_iam_user.user.name}"
}

resource "aws_iam_user_policy" "policy" {
  name = "sos-user"
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::save-our-summer-images/*"
    }
  ]
}
EOF
}
