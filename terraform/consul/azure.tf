resource "azurerm_public_ip" "consul" {
  name                = "consul-ip"
  location            = "West US"
  resource_group_name = data.terraform_remote_state.infra.outputs.azure_rg
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "consul" {
  name                = "consul-nic"
  location            = "West US"
  resource_group_name = data.terraform_remote_state.infra.outputs.azure_rg

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = data.terraform_remote_state.infra.outputs.azure_shared_svcs_public_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.consul.id
  }
}

resource "azurerm_virtual_machine" "consul" {
  name                  = "consul-vm"
  location              = "West US"
  resource_group_name   = data.terraform_remote_state.infra.outputs.azure_rg
  network_interface_ids = [azurerm_network_interface.consul.id]
  vm_size               = "Standard_D1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "consul-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "consul"
    admin_username = "azure-user"
    custom_data    = data.template_file.azure-init.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azure-user/.ssh/authorized_keys"
      key_data = data.terraform_remote_state.infra.outputs.ssh_key_public_key_openssh
    }
  }

  tags = {
    environment = "staging"
  }
}

data "template_file" "azure-init" {
  template = "${file("${path.module}/scripts/azure_consul.sh")}"
}

resource "azurerm_network_security_group" "consul" {
  name                = "consul-nsg"
  location            = "West US"
  resource_group_name = data.terraform_remote_state.infra.outputs.azure_rg

  # Allow SSH traffic in from Internet to public subnet.
  security_rule {
    name                       = "allow-ssh-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH traffic in from Internet to public subnet.
  security_rule {
    name                       = "allow-api-all"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "consul" {
  network_interface_id      = azurerm_network_interface.consul.id
  network_security_group_id = azurerm_network_security_group.consul.id
}


resource "helm_release" "azure-consul" {
  name       = "azure-consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  values = [
    "${file("helm/consul-aks.yaml")}"
  ]
}
