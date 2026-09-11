variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "medlogix-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS managed node group"
  type        = string
  default     = "t3.medium"
  # Cost: ~$0.052/hr on-demand in ap-southeast-1
  # Use t3.small ($0.026/hr) to cut cost further — but Spring Boot needs ≥ 512MB heap
}

variable "node_desired_count" {
  type    = number
  default = 2
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "github_org" {
  description = "GitHub org or username (for OIDC trust policy)"
  type        = string
  # Replace with your GitHub username, e.g. "johndoe"
  default     = "<GITHUB_USER>"
}

variable "github_repo" {
  description = "GitHub repository name (for OIDC trust policy)"
  type        = string
  # Replace with your repo name, e.g. "Patient-Microservice"
  default     = "<GITHUB_REPO>"
}
