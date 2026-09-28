resource "azurerm_subnet" "hub_firewallsub" {
  name = "AzureFirewallSubnet"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes = [var.fwsub]
}

resource "azurerm_subnet" "hub_appgwsub" {
  name = "appgw-sub"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes = [var.appgwsub]
}

resource "azurerm_subnet" "hub_vpngwsub" {
  name = "GatewaySubnet"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes = [var.vpngwsub]
}

resource "azurerm_subnet" "hub_batsub" {
  name                 = "AzureBastionSubnet"  
  resource_group_name  = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name  
  address_prefixes     = [var.batsub]
}

resource "azurerm_subnet" "web_spoke_websub" {
  name = "websub"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.web_spoke_vnet.name
  address_prefixes = [var.websub]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "web_spoke_wassub" {
  name                 = "wassub"
  resource_group_name  = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.web_spoke_vnet.name
  address_prefixes     = [var.wassub]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "web_spoke_PEsub" {
  name = "web-PEsub"
  resource_group_name = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.web_spoke_vnet.name
  address_prefixes = [var.webPEsub]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "db_spoke_dbsub" {
  name                 = "dbsub"
  resource_group_name  = azurerm_resource_group.rg_4team.name
  virtual_network_name = azurerm_virtual_network.db_spoke_vnet.name
  address_prefixes     = [var.dbsub]
  default_outbound_access_enabled = false

  delegation {
    name = "flexible-server-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}