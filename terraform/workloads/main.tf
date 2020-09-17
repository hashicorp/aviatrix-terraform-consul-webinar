provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

provider "azurerm" {
  version = "=2.0.0"
  features {}
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"
  }
}
