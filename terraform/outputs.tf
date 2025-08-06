output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.photo_gallery_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster."
  value       = aws_eks_cluster.photo_gallery_cluster.endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.photo_gallery_cluster.version
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket created for images."
  value       = aws_s3_bucket.photo_gallery_bucket.id
}

output "s3_irsa_role_arn" {
  description = "The ARN of the IAM role for S3 access via IRSA."
  value       = aws_iam_role.s3_irsa_role.arn
}
