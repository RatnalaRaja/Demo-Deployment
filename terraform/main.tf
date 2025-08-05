# terraform/main.tf
# This file ties together the various modules and resources.
# It sets up the AWS provider and configures the Kubernetes and Helm providers
# to interact with the EKS cluster created by other Terraform files.

provider "aws" {
  region = var.aws_region
}

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get available availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Configure Kubernetes provider to connect to the EKS cluster
# This depends on the EKS cluster being created first.
provider "kubernetes" {
  host                   = aws_eks_cluster.photo_gallery_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.photo_gallery_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.photo_gallery_cluster_auth.token
}

# Configure Helm provider to connect to the EKS cluster
# This depends on the EKS cluster being created first.
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.photo_gallery_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.photo_gallery_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.photo_gallery_cluster_auth.token
  }
}