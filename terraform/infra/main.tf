provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

provider "azurerm" {
  version = "=2.13.0"
  features {}
}

provider "azuread" {
  version = "=0.10.0"
}

resource "random_string" "env" {
  length  = 4
  special = false
  upper   = false
  number  = false
}

#ssh
resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > ../demo-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ../demo-key.pem"
  }
}
