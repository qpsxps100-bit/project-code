resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  address_space       = [var.hubcidr]
  depends_on          = [azurerm_resource_group.rg_4team]
}

resource "azurerm_virtual_network" "web_spoke_vnet" {
  name                = "web-spoke-vnet"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  address_space       = [var.webspokecidr]
  depends_on          = [azurerm_resource_group.rg_4team]
}

resource "azurerm_virtual_network" "db_spoke_vnet" {
  name                = "db-spoke-vnet"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  address_space       = [var.dbspokecidr]
  depends_on          = [azurerm_resource_group.rg_4team]
}