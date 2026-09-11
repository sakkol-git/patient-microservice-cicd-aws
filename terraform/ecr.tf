# ─── AWS ECR Repositories ─────────────────────────────────────────────────────
# Private registries for all three container images.
# EKS pulls from these via IAM — no Kubernetes imagePullSecret needed.

locals {
  ecr_repos = ["patient-service", "audit-service", "api-gateway"]
}

resource "aws_ecr_repository" "medlogix" {
  for_each = toset(local.ecr_repos)

  name                 = "medlogix/${each.key}"
  image_tag_mutability = "MUTABLE" # allows :latest tag to be overwritten

  image_scanning_configuration {
    scan_on_push = true # free basic scan catches known CVEs on every push
  }

  tags = {
    Service = each.key
  }
}

# ─── ECR Lifecycle Policy ──────────────────────────────────────────────────────
# Keep the last 10 tagged images per service.
# Untagged layers (e.g. dangling images from a failed push) are removed after 1 day.
resource "aws_ecr_lifecycle_policy" "medlogix" {
  for_each   = aws_ecr_repository.medlogix
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
