
# terraform/alb-ingress.tf
# Deploys the AWS Load Balancer Controller using Helm.

resource "kubernetes_namespace" "alb_ingress_namespace" {
  metadata {
    name = "aws-load-balancer-controller"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.alb_ingress_namespace.metadata[0].name
  version    = "1.7.1" # Check for the latest compatible version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # IAM Role for Service Account for ALB Ingress Controller
  # This role allows the ALB controller to create/manage ALBs.
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_irsa_role.arn
    type  = "string"
  }

  # Ensure the controller is deployed after the EKS cluster is ready
  depends_on = [
    aws_eks_cluster.photo_gallery_cluster,
    aws_iam_role_policy_attachment.alb_controller_irsa_policy_attachment,
  ]
}

# IAM Role for Service Account (IRSA) for ALB Ingress Controller
resource "aws_iam_role" "alb_controller_irsa_role" {
  name = "photo-gallery-alb-controller-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.photo_gallery_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.photo_gallery_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:aws-load-balancer-controller:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Name = "photo-gallery-alb-controller-irsa-role"
  }
}

# Policy for ALB Ingress Controller permissions
# This policy is required for the ALB controller to manage ALBs, security groups, etc.
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "photo-gallery-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"

  policy = file("iam_policy_alb_controller.json") # Load policy from a file
}

resource "aws_iam_role_policy_attachment" "alb_controller_irsa_policy_attachment" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa_role.name
}

# Create a file for the ALB Ingress Controller IAM policy
# terraform/iam_policy_alb_controller.json
# This policy is taken from the official AWS Load Balancer Controller documentation.
# For the most up-to-date policy, always refer to:
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
