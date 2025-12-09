# Copyright IBM Corp. 2020, 2023
# SPDX-License-Identifier: MPL-2.0

output "aws_consul_public_ip" {
  value = aws_instance.consul.public_ip
}

output "azure_consul_public_ip" {
  value = azurerm_public_ip.consul.ip_address
}
