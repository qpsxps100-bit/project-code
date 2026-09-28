resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.rgname}-law"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "mysql_diag" {
  name                       = "mysql-diag"
  target_resource_id         = azurerm_mysql_flexible_server.mysql.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "MySqlSlowLogs" }
  enabled_log { category = "MySqlAuditLogs" }
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "appgw-diag"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }
}

resource "azurerm_monitor_diagnostic_setting" "fw_diag" {
  name                       = "fw-diag"
  target_resource_id         = azurerm_firewall.hub_fw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category_group = "allLogs" }
}