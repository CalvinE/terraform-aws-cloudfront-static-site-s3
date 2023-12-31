resource "aws_s3_bucket" "site" {
  # TODO: over thinking here, but could this cause a collision? Should we use bucket_prefix?
  bucket = var.domain_name
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid    = "PublicReadGetObjectCFPrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site.id}"]
    }
  }
  statement {
    sid    = "PublicReadGetObjectCFOAI"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

### Site logs bucket

resource "aws_s3_bucket" "logs" {
  # TODO: over thinging here, but could this cause a collision? Should we use bucket_prefix?
  bucket = "${var.domain_name}-logs"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}
