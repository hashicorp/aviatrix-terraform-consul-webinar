# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "aviatrix_controller_public_ip" {
  value = module.aviatrix-controller-build.public_ip
}

output "aviatrix_controller_private_ip" {
  value = module.aviatrix-controller-build.private_ip
}

output "aviatrix_controller_password" {
  value = random_string.password.result
}
