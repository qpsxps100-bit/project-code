resource "azurerm_route_table" "spoke_rt" {
  name                = "spoke-rt"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_route" "default_to_fw" {
  name                   = "default-to-firewall"
  resource_group_name    = azurerm_resource_group.rg_4team.name
  route_table_name       = azurerm_route_table.spoke_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "web_rt_asso" {
  subnet_id      = azurerm_subnet.web_spoke_websub.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

resource "azurerm_subnet_route_table_association" "db_rt_asso" {
  subnet_id      = azurerm_subnet.db_spoke_dbsub.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

resource "azurerm_subnet_route_table_association" "was_rt_asso" {
  subnet_id      = azurerm_subnet.web_spoke_wassub.id
  route_table_id = azurerm_route_table.spoke_rt.id
}