# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "rajaphotogallerybucketforproject-public" # Replace with a unique S3 bucket name
    key            = "photo-gallery/terraform.tfstate"
    region         = "us-east-1" # e.g., "us-east-1"
    encrypt        = true
  }
}
