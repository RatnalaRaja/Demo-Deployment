# terraform/eks.tf
# Configures the EKS cluster and its node groups.



resource "aws_eks_cluster" "photo_gallery_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28" # Specify your desired Kubernetes version

  vpc_config {
    subnet_ids = aws_subnet.photo_gallery_public_subnets[*].id
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  tags = {
    Name = var.cluster_name
  }

  # Ensure that the EKS cluster is created before proceeding with node groups
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_role_policy_attachment.eks_vpc_cni_policy_attachment, # Required for EKS to manage ENIs
  ]
}

resource "aws_eks_node_group" "photo_gallery_node_group" {
  cluster_name    = aws_eks_cluster.photo_gallery_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.photo_gallery_public_subnets[*].id # Deploy nodes in public subnets
  instance_types  = [var.instance_type]



  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that the node group is created after the cluster and its IAM role
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_ecr_policy_attachment,
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}

# Data source for EKS cluster authentication
data "aws_eks_cluster_auth" "photo_gallery_cluster_auth" {
  name = aws_eks_cluster.photo_gallery_cluster.name
}
