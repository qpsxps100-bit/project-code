resource "azurerm_traffic_manager_profile" "tm" {
  count                   = var.tm_profile ? 1 : 0
  name                    = "team4-traficmanager"
  resource_group_name     = azurerm_resource_group.rg_4team.name
  traffic_routing_method  = "Priority"

  dns_config {
    relative_name = "team4-dr"
    ttl           = 30
  }

  monitor_config {
  protocol = "HTTP"
  port     = 80
  path     = "/health.php"
}
}

data "azurerm_traffic_manager_profile" "tm" {
  count                = var.tm_profile ? 0 : 1
  name                 = "team4-traficmanager"
  resource_group_name  = "07-4team-kr"  
}

locals {
  tm_profile_id = var.tm_profile ? azurerm_traffic_manager_profile.tm[0].id : data.azurerm_traffic_manager_profile.tm[0].id
}

resource "azurerm_traffic_manager_azure_endpoint" "self_endpoint" {
  name                = "${var.rgname}-endpoint"
  profile_id          = local.tm_profile_id
  target_resource_id  = azurerm_public_ip.appgw_pip.id   
  priority            = var.tm_priority
}