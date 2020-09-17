output "env" {
  value = random_string.env.result
}

output "ssh_key_public_key_openssh" {
  value = tls_private_key.main.public_key_openssh
}

output "aws_ssh_key_name" {
  value = aws_key_pair.demo.key_name
}

output "aws_transit_vpc" {
  value = module.vpc-transit.vpc_id
}

output "aws_transit_public_subnets" {
  value = module.vpc-transit.public_subnets
}

output "aws_shared_svcs_vpc" {
  value = module.vpc-shared-svcs.vpc_id
}

output "aws_shared_svcs_public_subnets" {
  value = module.vpc-shared-svcs.public_subnets
}

output "aws_app_vpc" {
  value = module.vpc-app.vpc_id
}

output "aws_app_public_subnets" {
  value = module.vpc-app.public_subnets
}

output "aws_app_private_subnets" {
  value = module.vpc-app.private_subnets
}

output "azure_rg" {
  value = azurerm_resource_group.aviatrix.name
}

output "azure_transit_vpc" {
  value = module.transit-network.vnet_name
}

output "azure_shared_svcs_vpc" {
  value = module.shared-svcs-network.vnet_name
}

output "azure_shared_svcs_public_subnets" {
  value = module.shared-svcs-network.vnet_subnets
}

output "azure_app_vpc" {
  value = module.app-network.vnet_name
}

output "azure_app_public_subnets" {
  value = module.app-network.vnet_subnets
}

output "azure_kube_config" {
  value = azurerm_kubernetes_cluster.app.kube_config_raw
}

output "azure_aviatrix_arm_application_id" {
  value = azuread_application.aviatrix.application_id
}

output "azure_aviatrix_arm_application_key" {
  value     = random_string.password.result
  sensitive = true
}
