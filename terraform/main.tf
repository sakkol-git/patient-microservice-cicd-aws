terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  # Optional: uncomment to store state in S3 (recommended for team use)
  # backend "s3" {
  #   bucket = "<your-terraform-state-bucket>"
  #   key    = "medlogix/terraform.tfstate"
  #   region = "ap-southeast-1"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "medlogix"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# ─── Data sources ─────────────────────────────────────────────────────────────
data "aws_availability_zones" "available" {
  state = "available"
}

# ─── VPC ──────────────────────────────────────────────────────────────────────
# 3 public subnets (NAT gateways, load balancers) + 3 private subnets (EKS nodes)
# Cost: 1 NAT gateway = ~$0.059/hr + data transfer in ap-southeast-1
# To cut cost to $0: use only public subnets (remove NAT GW) — acceptable for testing

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true  # 1 NAT GW = ~$0.06/hr; set false for HA (3x cost)
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Required tags for EKS to discover subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = 1
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = 1
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
  }
}

# ─── EKS Cluster ──────────────────────────────────────────────────────────────
# Control plane: $0.10/hr while cluster exists — DESTROY when done testing
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true  # Allow kubectl from your laptop
  # Security note: restrict to your IP in production:
  # cluster_endpoint_public_access_cidrs = ["<YOUR_IP>/32"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Managed node group — AWS handles node upgrades, draining, replacement
  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_count
      max_size       = var.node_max_count
      desired_size   = var.node_desired_count

      # Nodes run on private subnets — not directly accessible from internet
      subnet_ids = module.vpc.private_subnets
    }
  }

  # Allow your local kubectl to access the cluster (add your IAM user/role ARN)
  enable_cluster_creator_admin_permissions = true
}

# ─── Helm Provider Configuration ──────────────────────────────────────────────
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# ─── RabbitMQ Helm Release ────────────────────────────────────────────────────
resource "helm_release" "rabbitmq" {
  name       = "rabbitmq"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  namespace  = "medlogix"
  create_namespace = true

  set {
    name  = "auth.username"
    value = "guest"
  }

  set {
    name  = "auth.password"
    value = "guest"
  }

  # For cost/resource efficiency in this sample project
  set {
    name  = "replicaCount"
    value = "1"
  }
}
