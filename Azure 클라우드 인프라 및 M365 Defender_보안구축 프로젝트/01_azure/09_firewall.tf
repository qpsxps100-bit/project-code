resource "azurerm_firewall" "hub_fw" {
  name                = "hub-firewall"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub_fw_policy.id

  ip_configuration {
    name                 = "fw-ip-conf"
    subnet_id            = azurerm_subnet.hub_firewallsub.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  depends_on = [azurerm_subnet.hub_firewallsub, azurerm_public_ip.fw_pip]
}