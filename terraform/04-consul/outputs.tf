output "aws_consul_public_ip" {
  value = aws_instance.consul.public_ip
}

output "azure_consul_public_ip" {
  value = azurerm_public_ip.consul.ip_address
}
