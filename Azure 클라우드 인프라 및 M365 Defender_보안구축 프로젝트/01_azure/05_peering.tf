resource "azurerm_virtual_network_peering" "hub_webspoke" {
  name = "hub-webspoke"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_spoke_vnet.id
  allow_forwarded_traffic = true
  allow_gateway_transit = true
  allow_virtual_network_access = true
  use_remote_gateways = false
}

resource "azurerm_virtual_network_peering" "webspoke_hub" {
  name = "webspoke-hub"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.web_spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic = true
  allow_gateway_transit = false
  allow_virtual_network_access = true
  use_remote_gateways = true
  depends_on = [azurerm_virtual_network_gateway.vpngw]
}

resource "azurerm_virtual_network_peering" "webspoke_dbspoke" {
  name = "webspoke-dbspoke"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.web_spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.db_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "dbspoke_webspoke" {
  name = "dbspoke-webspoke"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.db_spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_dbspoke" {
  name                         = "hub-dbspoke"
  resource_group_name          = azurerm_resource_group.rg_4team.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.db_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true    
  allow_virtual_network_access = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "dbspoke_hub" {
  name                         = "dbspoke-hub"
  resource_group_name          = azurerm_resource_group.rg_4team.name
  virtual_network_name         = azurerm_virtual_network.db_spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = true    
  depends_on = [azurerm_virtual_network_gateway.vpngw]
}