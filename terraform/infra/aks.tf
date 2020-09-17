resource "azurerm_kubernetes_cluster" "app" {
  name                = "app-aks"
  resource_group_name = azurerm_resource_group.aviatrix.name
  location            = "West US"
  dns_prefix          = "app"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = module.app-network.vnet_subnets[0]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  tags = {
    Environment = "Production"
  }

  provisioner "local-exec" {
    command = "echo azurerm_kubernetes_cluster.example.kube_config_raw > kube_config/kubeconfig_azure"
  }

}

resource "azurerm_role_assignment" "aks" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.app.kubelet_identity[0].object_id
}
