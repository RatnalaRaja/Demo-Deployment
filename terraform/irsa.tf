data "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.photo_gallery_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "s3_irsa_role" {
  name = "${var.cluster_name}-irsa-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.photo_gallery_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:s3-access-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_irsa_policy" {
  name = "${var.cluster_name}-irsa-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.photo_gallery_bucket.arn,
          "${aws_s3_bucket.photo_gallery_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_irsa_policy" {
  role       = aws_iam_role.s3_irsa_role.name
  policy_arn = aws_iam_policy.s3_irsa_policy.arn
}
