resource "azurerm_mysql_flexible_server" "mysql" {

  name                = var.mysql_server_name
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"
  delegated_subnet_id = azurerm_subnet.db_spoke_dbsub.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql_dns.id

  storage {
    size_gb = 20
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql_dns_link
  ]
}

resource "azurerm_mysql_flexible_database" "empdb" {

  name                = var.app_db_name
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {

  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  value = "OFF"
}

resource "azurerm_mysql_flexible_server_configuration" "slow_query_log" {

  name                = "slow_query_log"
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  value = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "long_query_time" {

  name                = "long_query_time"
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  value = "1"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_enabled" {

  name                = "audit_log_enabled"
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  value = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_events" {

  name                = "audit_log_events"
  resource_group_name = azurerm_resource_group.rg_4team.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  value = "CONNECTION"
}