resource "azurerm_managed_redis" "redis" {
  name                  = "team4-redis"
  resource_group_name   = azurerm_resource_group.rg_4team.name
  location              = azurerm_resource_group.rg_4team.location
  sku_name              = "Balanced_B0"
  public_network_access = "Disabled"

  default_database {
    access_keys_authentication_enabled = true
    clustering_policy                  = "EnterpriseCluster"
  }
}