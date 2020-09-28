provider "aviatrix" {
  username                = "admin"
  controller_ip           = data.terraform_remote_state.aviatrix.outputs.aviatrix_controller_public_ip
  password                = data.terraform_remote_state.aviatrix.outputs.aviatrix_controller_password
  skip_version_validation = true
}

provider "azurerm" {
  version = "=2.13.0"
  features {}
}

data "terraform_remote_state" "aviatrix" {
  backend = "local"

  config = {
    path = "../02-aviatrix/terraform.tfstate"
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../01-infra/terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}

#link the controller to Azure
resource "aviatrix_account" "azure" {
  account_name        = "azure-demo"
  cloud_type          = 8
  arm_subscription_id = data.azurerm_client_config.current.subscription_id
  arm_directory_id    = data.azurerm_client_config.current.tenant_id
  arm_application_id  = data.terraform_remote_state.infra.outputs.azure_aviatrix_arm_application_id
  arm_application_key = data.terraform_remote_state.infra.outputs.azure_aviatrix_arm_application_key
}

resource "aviatrix_transit_gateway" "transit_gateway_aws" {
  cloud_type         = 1
  account_name       = "aws-demo"
  gw_name            = "transit-aws"
  vpc_id             = data.terraform_remote_state.infra.outputs.aws_transit_vpc
  vpc_reg            = "us-east-1"
  gw_size            = "t2.medium"
  subnet             = "10.1.3.0/24"
  enable_active_mesh = true
  connected_transit  = true
}

resource "aviatrix_spoke_gateway" "shared_svcs_spoke_gateway_aws" {
  cloud_type         = 1
  account_name       = "aws-demo"
  gw_name            = "shared-svcs-spoke-gw-aws"
  vpc_id             = data.terraform_remote_state.infra.outputs.aws_shared_svcs_vpc
  vpc_reg            = "us-east-1"
  gw_size            = "t2.medium"
  subnet             = "10.2.3.0/24"
  enable_active_mesh = true
  transit_gw         = "transit-aws"
}

resource "aviatrix_spoke_gateway" "app_spoke_gateway_aws" {
  cloud_type         = 1
  account_name       = "aws-demo"
  gw_name            = "app-spoke-gw-aws"
  vpc_id             = data.terraform_remote_state.infra.outputs.aws_app_vpc
  vpc_reg            = "us-east-1"
  gw_size            = "t2.medium"
  subnet             = "10.3.3.0/24"
  enable_active_mesh = true
  transit_gw         = "transit-aws"
}

resource "aviatrix_transit_gateway" "transit_gateway_azure" {
  depends_on = [aviatrix_account.azure]

  cloud_type         = 8
  account_name       = "azure-demo"
  gw_name            = "transit-azure"
  vpc_id             = "${data.terraform_remote_state.infra.outputs.azure_transit_vpc}:${data.terraform_remote_state.infra.outputs.azure_rg}"
  vpc_reg            = "West US"
  gw_size            = "Standard_D2"
  subnet             = "10.4.0.0/24"
  connected_transit  = true
  enable_active_mesh = true
}

resource "aviatrix_spoke_gateway" "shared_svcs_spoke_gateway_azure" {
  depends_on = [aviatrix_account.azure]

  cloud_type         = 8
  account_name       = "azure-demo"
  gw_name            = "shared-svcs-spoke-gw-azure"
  vpc_id             = "${data.terraform_remote_state.infra.outputs.azure_shared_svcs_vpc}:${data.terraform_remote_state.infra.outputs.azure_rg}"
  vpc_reg            = "West US"
  gw_size            = "Standard_B1ms"
  subnet             = "10.5.0.0/24"
  enable_active_mesh = true
  transit_gw         = "transit-azure"
}

resource "aviatrix_spoke_gateway" "app_spoke_gateway_azure" {
  depends_on = [aviatrix_account.azure]

  cloud_type         = 8
  account_name       = "azure-demo"
  gw_name            = "app-spoke-gw-azure"
  vpc_id             = "${data.terraform_remote_state.infra.outputs.azure_app_vpc}:${data.terraform_remote_state.infra.outputs.azure_rg}"
  vpc_reg            = "West US"
  gw_size            = "Standard_B1ms"
  subnet             = "10.6.0.0/24"
  enable_active_mesh = true
  transit_gw         = "transit-azure"
}

resource "aviatrix_transit_gateway_peering" "aws_azure_gateway_peering" {
  depends_on = [aviatrix_transit_gateway.transit_gateway_azure, aviatrix_transit_gateway.transit_gateway_aws]

  transit_gateway_name1 = "transit-aws"
  transit_gateway_name2 = "transit-azure"
}
