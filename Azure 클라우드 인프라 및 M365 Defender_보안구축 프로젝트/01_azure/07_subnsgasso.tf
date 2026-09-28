resource "azurerm_subnet_network_security_group_association" "appgw_nsg_asso" {
  subnet_id                 = azurerm_subnet.hub_appgwsub.id
  network_security_group_id = azurerm_network_security_group.nsg_appgw.id
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_asso" {
  subnet_id                 = azurerm_subnet.web_spoke_websub.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

resource "azurerm_subnet_network_security_group_association" "was_nsg_asso" {
  subnet_id                 = azurerm_subnet.web_spoke_wassub.id
  network_security_group_id = azurerm_network_security_group.nsg_was.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_asso" {
  subnet_id                 = azurerm_subnet.db_spoke_dbsub.id   
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

resource "azurerm_subnet_network_security_group_association" "bastion_nsg_asso" {
  subnet_id                 = azurerm_subnet.hub_batsub.id
  network_security_group_id = azurerm_network_security_group.nsg_bastion.id
}