resource "azurerm_virtual_network_gateway" "vpngw" {
  name                = "hub-vpn-gateway"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"

  ip_configuration {
    name                           = "vpngw-ip-conf"
    public_ip_address_id          = azurerm_public_ip.vpngw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                      = azurerm_subnet.hub_vpngwsub.id
  }

  depends_on = [azurerm_subnet.hub_vpngwsub, azurerm_public_ip.vpngw_pip]
}

resource "azurerm_virtual_network_gateway_connection" "onprem_conn" {
  name                       = "hub-to-onprem"
  resource_group_name        = azurerm_resource_group.rg_4team.name
  location                   = azurerm_resource_group.rg_4team.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem_db.id
  shared_key                 = var.vpn_shared_key

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_lifetime      = 27000
  }
}

resource "azurerm_local_network_gateway" "onprem_db" {
  name                = "onprem-db-gateway"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  gateway_address     = var.onprem_gateway_ip
  address_space = [var.onprem_cidr, var.admin_cidr]
}