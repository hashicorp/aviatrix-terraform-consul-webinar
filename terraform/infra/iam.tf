data "azurerm_subscription" "primary" {}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azuread_application" "aviatrix" {
  name = "aviatrix-${random_string.env.result}"
}

resource "azuread_application_password" "aviatrix" {
  application_object_id = azuread_application.aviatrix.id
  value                 = random_string.password.result
  end_date_relative     = "17520h"
}

resource "azuread_service_principal" "aviatrix" {
  application_id = azuread_application.aviatrix.application_id
}

resource "azurerm_role_assignment" "aviatrix" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aviatrix.id
}
