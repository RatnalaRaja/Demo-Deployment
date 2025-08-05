
# terraform/s3.tf
# Creates the S3 bucket for storing images.

resource "aws_s3_bucket" "photo_gallery_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "${var.cluster_name}-s3-bucket"
  }
}

# Block public access to the S3 bucket by default
resource "aws_s3_bucket_public_access_block" "photo_gallery_bucket_public_access_block" {
  bucket = aws_s3_bucket.photo_gallery_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy to allow read/write from IAM Role for Service Account
# This policy will be attached to the S3 bucket.
resource "aws_s3_bucket_policy" "photo_gallery_bucket_policy" {
  bucket = aws_s3_bucket.photo_gallery_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.s3_irsa_role.arn # Allow the IRSA role to access this bucket
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.photo_gallery_bucket.arn,
          "${aws_s3_bucket.photo_gallery_bucket.arn}/*"
        ]
      },
      # Optional: Add a policy for public read if you want direct S3 URLs
      # This contradicts `block_public_access_block` above, so choose one.
      # For this setup, we're using the backend to proxy, so this isn't strictly needed.
      # If you want direct public access to images, you would remove the public access block
      # and add a bucket policy like this:
      # {
      #   Effect = "Allow",
      #   Principal = "*",
      #   Action = "s3:GetObject",
      #   Resource = "${aws_s3_bucket.photo_gallery_bucket.arn}/*"
      # }
    ]
  })
}
