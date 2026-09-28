resource "azurerm_bastion_host" "bastion" {
  name = "bastion"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  sku = "Basic"

  ip_configuration {
    name = "bat-ip-conf"
    subnet_id = azurerm_subnet.hub_batsub.id
    public_ip_address_id = azurerm_public_ip.bat_pip.id
  }
}