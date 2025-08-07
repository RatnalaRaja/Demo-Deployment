# terraform/variables.tf
# Defines input variables for your Terraform configuration.
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Change to your desired region
}

variable "cluster_name" {
  description = "The name for the EKS cluster."
  type        = string
  default     = "photo-gallery-eks-cluster-public"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Adjust based on your region's AZs
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"] # Adjust based on your region's AZs
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium" # Consider t3.large or m5.large for production
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket to store images."
  type        = string
  default     = "photo-gallery-images-public-12345678" # IMPORTANT: Must be globally unique!
}
