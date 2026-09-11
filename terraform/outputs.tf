output "cluster_name" {
  description = "EKS cluster name — use in: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "github_actions_role_arn" {
  description = "Paste this as the AWS_DEPLOY_ROLE_ARN GitHub Actions secret"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "configure_kubectl" {
  description = "Command to configure local kubectl after cluster creation"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

output "cost_reminder" {
  description = "Reminder to tear down resources when done"
  value       = "⚠️  EKS control plane costs ~$0.10/hr. Run 'terraform destroy' when done testing."
}

output "ecr_repository_urls" {
  description = "ECR repository URIs — use these in your k8s deployment manifests and CI/CD"
  value       = { for k, v in aws_ecr_repository.medlogix : k => v.repository_url }
}
