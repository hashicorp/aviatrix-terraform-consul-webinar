data "aws_eks_cluster" "app" {
  name = module.app.cluster_id
}

data "aws_eks_cluster_auth" "app" {
  name = module.app.cluster_id
}

provider "kubernetes" {
  alias                  = "app"
  host                   = data.aws_eks_cluster.app.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.app.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "app" {
  source = "terraform-aws-modules/eks/aws"
  providers = {
    kubernetes = kubernetes.app
  }
  cluster_name                         = "app"
  cluster_version                      = "1.16"
  subnets                              = flatten([module.vpc-app.private_subnets])
  vpc_id                               = module.vpc-app.vpc_id
  worker_additional_security_group_ids = [aws_security_group.app-eks-consul.id]

  manage_aws_auth    = true
  write_kubeconfig   = true
  config_output_path = "kube_config/kubeconfig_aws"

  worker_groups = [
    {
      instance_type        = "t3.large"
      asg_max_size         = 1
      asg_desired_capacity = 1
    }
  ]
}

resource "aws_security_group" "app-eks-consul" {
  name        = "consul-app-eks"
  description = "consul-app-eks"
  vpc_id      = module.vpc-app.vpc_id

  ingress {
    from_port   = 20000
    to_port     = 20000
    protocol    = "tcp"
    cidr_blocks = ["10.6.0.0/16"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["10.2.0.0/16"]
  }

}
