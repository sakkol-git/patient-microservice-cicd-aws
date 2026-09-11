# ─── GitHub Actions OIDC provider ─────────────────────────────────────────────
# Allows GitHub Actions to assume an IAM role without storing long-lived AWS keys.
# Created as a resource because this is the first time deploying to this AWS account.
# Safe to run multiple times — if it already exists, import it with:
#   terraform import aws_iam_openid_connect_provider.github <provider-arn>
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f8d264fcd9"
  ]
}

# ─── IAM role assumed by GitHub Actions CI/CD ─────────────────────────────────
resource "aws_iam_role" "github_actions_deploy" {
  name = "medlogix-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Scope trust to your repo (supports both refs/heads/main and environment deployments)
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# ─── Policy: just enough to deploy to EKS ─────────────────────────────────────
# Least-privilege: only eks:DescribeCluster + eks:UpdateKubeconfig equivalent
resource "aws_iam_role_policy" "github_actions_eks" {
  name = "medlogix-eks-deploy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

# ─── Policy: ECR push (so CI/CD can build & push images) ──────────────────────
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "medlogix-ecr-push"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow the role to authenticate with ECR
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # Allow push/pull to medlogix/* repositories only (least privilege)
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories"
        ]
        Resource = [for repo in aws_ecr_repository.medlogix : repo.arn]
      }
    ]
  })
}

# The GitHub Actions IAM role also needs to be granted K8s RBAC permissions.
# After cluster creation, run:
#   kubectl create clusterrolebinding github-actions-deploy \
#     --clusterrole=cluster-admin \
#     --user=<ARN of medlogix-github-actions-deploy role>
# Production: use a least-privilege ClusterRole (only patch deployments in medlogix namespace)
