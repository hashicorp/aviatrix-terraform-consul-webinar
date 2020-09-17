resource "aws_key_pair" "demo" {
  key_name   = "aviatrix-demo-${random_string.env.result}"
  public_key = tls_private_key.main.public_key_openssh
}

module "vpc-transit" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "terraform-vpc-transit-${random_string.env.result}"

  cidr = "10.1.0.0/16"

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.3.0/24", "10.1.4.0/24", "10.1.5.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = { "Tier" : "private" }
  public_subnet_tags  = { "Tier" : "public" }
  vpc_tags            = { "Owner" : "aviatrix-demo" }

}

module "vpc-shared-svcs" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "terraform-vpc-shared-svcs-${random_string.env.result}"

  cidr = "10.2.0.0/16"

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  public_subnets  = ["10.2.3.0/24", "10.2.4.0/24", "10.2.5.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = { "Tier" : "private" }
  public_subnet_tags  = { "Tier" : "public" }
  vpc_tags            = { "Owner" : "aviatrix-demo" }
}

module "vpc-app" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "terraform-vpc-app-${random_string.env.result}"

  cidr = "10.3.0.0/16"

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets = ["10.3.0.0/24", "10.3.1.0/24", "10.3.2.0/24"]
  public_subnets  = ["10.3.3.0/24", "10.3.4.0/24", "10.3.5.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = { "Tier" : "private" }
  public_subnet_tags  = { "Tier" : "public", "kubernetes.io/cluster/app" : "shared", "kubernetes.io/role/elb" : "1" }
  vpc_tags            = { "kubernetes.io/cluster/app" : "shared", "Owner" : "aviatrix-demo" }
}
