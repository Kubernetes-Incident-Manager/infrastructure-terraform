data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "pod_identity" {
  name                = "incident-tracker-pod-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_key_vault_access_policy" "pod_policy" {
  key_vault_id = module.keyvault.kv_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.pod_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_federated_identity_credential" "fic" {
  name      = "incident-tracker-fic"
  audience  = ["api://AzureADTokenExchange"]
  issuer    = module.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.pod_identity.id
  subject   = "system:serviceaccount:dev:incident-tracker-sa"
}

resource "azurerm_key_vault_access_policy" "terraform_executor" {
  key_vault_id       = module.keyvault.kv_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Set", "Get", "Delete", "Purge", "Recover"]
}

resource "azurerm_role_assignment" "terraform_secrets_officer" {
  scope                = module.keyvault.kv_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "pod_secrets_user" {
  scope                = module.keyvault.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.pod_identity.principal_id
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "postgres-username"
  value        = var.sql_admin_username
  key_vault_id = module.keyvault.kv_id
  depends_on   = [azurerm_key_vault_access_policy.terraform_executor, azurerm_role_assignment.terraform_secrets_officer]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "postgres-password"
  value        = var.sql_admin_password
  key_vault_id = module.keyvault.kv_id
  depends_on   = [azurerm_key_vault_access_policy.terraform_executor, azurerm_role_assignment.terraform_secrets_officer]
}

resource "azurerm_key_vault_secret" "db_host" {
  name         = "postgres-host"
  value        = module.database.sql_server_fqdn
  key_vault_id = module.keyvault.kv_id
  depends_on   = [azurerm_key_vault_access_policy.terraform_executor, azurerm_role_assignment.terraform_secrets_officer]
}
