resource "azurerm_resource_group" "aviatrix" {
  name     = "aviatrix-${random_string.env.result}"
  location = "West US"
}

module "transit-network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "terraform-transit-vnet-${random_string.env.result}"
  resource_group_name = azurerm_resource_group.aviatrix.name
  address_space       = "10.4.0.0/16"
  subnet_prefixes     = ["10.4.0.0/24"]
  subnet_names        = ["aviatrix"]

  tags = {
    owner = "aviatrix-demo"
  }
}

module "shared-svcs-network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.aviatrix.name
  vnet_name           = "terraform-shared-svcs-vnet-${random_string.env.result}"
  address_space       = "10.5.0.0/16"
  subnet_prefixes     = ["10.5.0.0/24"]
  subnet_names        = ["shared"]

  tags = {
    owner = "aviatrix-demo"
  }
}

module "app-network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.aviatrix.name
  vnet_name           = "terraform-app-vnet-${random_string.env.result}"
  address_space       = "10.6.0.0/16"
  subnet_prefixes     = ["10.6.0.0/24"]
  subnet_names        = ["app"]

  tags = {
    owner = "aviatrix-demo"
  }
}
