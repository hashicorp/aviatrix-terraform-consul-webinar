provider "aviatrix" {
  username                = "admin"
  controller_ip           = module.aviatrix-controller-build.public_ip
  password                = module.aviatrix-controller-build.private_ip
  skip_version_validation = true
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"
  }
}

#data sources
data "aws_caller_identity" "current" {}

module "aviatrix-iam-roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles?ref=terraform_0.12"
}

module "aviatrix-controller-build" {
  source  = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-build?ref=terraform_0.12"
  vpc     = data.terraform_remote_state.infra.outputs.aws_shared_svcs_vpc
  subnet  = data.terraform_remote_state.infra.outputs.aws_shared_svcs_public_subnets[0]
  keypair = data.terraform_remote_state.infra.outputs.aws_ssh_key_name
  ec2role = module.aviatrix-iam-roles.aviatrix-role-ec2-name
}

module "aviatrix-controller-initialize" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize?ref=terraform_0.12"

  admin_password      = "Password1"
  admin_email         = "admin@example.com"
  private_ip          = module.aviatrix-controller-build.private_ip
  public_ip           = module.aviatrix-controller-build.public_ip
  access_account_name = "aws-demo"
  aws_account_id      = data.aws_caller_identity.current.account_id
  vpc_id              = data.terraform_remote_state.infra.outputs.aws_shared_svcs_vpc
  subnet_id           = data.terraform_remote_state.infra.outputs.aws_shared_svcs_public_subnets[0]
}
