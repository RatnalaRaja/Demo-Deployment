# terraform/versions.tf
# Defines the required Terraform version and AWS provider version.
terraform {
  required_version = ">= 1.0.0" # Ensure you have a compatible Terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a recent, stable version of the AWS provider
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23" # For managing Kubernetes resources
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11" # For deploying Helm charts (like ALB Ingress Controller)
    }
  }
}
