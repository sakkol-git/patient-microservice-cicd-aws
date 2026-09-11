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
  default     = "t3.small"
  # Free-tier eligible in ap-southeast-1; 2 vCPUs, 2 GB RAM
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
  default     = "sakkol-git"
}

variable "github_repo" {
  description = "GitHub repository name (for OIDC trust policy)"
  type        = string
  # Replace with your repo name, e.g. "Patient-Microservice"
  default     = "patient-microservice-cicd-aws"
}
