resource "azurerm_public_ip_prefix" "pip_prefix" {
  name                = "pip-prefix"
  location            = azurerm_resource_group.rg_4team.location
  resource_group_name = azurerm_resource_group.rg_4team.name

  prefix_length = 30
}

resource "azurerm_public_ip" "bat_pip" {
  name                = "bat-pip"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "appgw-pip"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
  domain_name_label = var.appgw_dns_label
}

resource "azurerm_public_ip" "fw_pip" {
  name                = "fw-pip"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
}

resource "azurerm_public_ip" "vpngw_pip" {
  name                = "vpngw-pip"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = ["1","2","3"]
}