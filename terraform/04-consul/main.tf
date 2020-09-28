provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

provider "azurerm" {
  version = "=2.13.0"
  features {}
}

provider "helm" {
  alias = "aws"
  kubernetes {
    config_path = "../01-infra/kube_config/kubeconfig_aws"
  }
}

provider "helm" {
  alias = "azure"
  kubernetes {
    config_path = "../01-infra/kube_config/kubeconfig_azure"
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../01-infra/terraform.tfstate"
  }
}
