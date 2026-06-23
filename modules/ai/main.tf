resource "azurerm_cognitive_account" "ai" {
  name                = "incidentfoundry-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags
}

resource "azurerm_ai_foundry" "hub" {
  name                = "incidentfoundry"
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_id        = var.key_vault_id
  storage_account_id  = var.storage_account_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_ai_foundry_project" "project" {
  name                = "suwethaproject"
  location            = var.location
  ai_services_hub_id  = azurerm_ai_foundry.hub.id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}