# terraform/s3.tf
# Creates the S3 bucket for storing images.

resource "aws_s3_bucket" "photo_gallery_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "${var.cluster_name}-s3-bucket"
  }
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
      # Add a policy for public read if you want direct S3 URLs
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.photo_gallery_bucket.arn}/*"
      }
    ]
  })
}
