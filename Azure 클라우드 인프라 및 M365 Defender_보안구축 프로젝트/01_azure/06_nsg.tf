resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-web"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location

  depends_on = [
    azurerm_resource_group.rg_4team
  ]
}

resource "azurerm_network_security_rule" "nsr_ssh" {
  name                        = "ssh-bat"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.batsub
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_web.name
}

resource "azurerm_network_security_rule" "nsr_http" {
  name                        = "http-inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.appgwsub
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_web.name
}

resource "azurerm_network_security_group" "nsg_appgw" {
  name                = "nsg-appgw"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_network_security_rule" "appgw_gatewaymanager" {
  name                        = "gatewaymanager"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_appgw.name
}

resource "azurerm_network_security_rule" "appgw_lb_probe" {
  name                        = "allow-lb-probe"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_appgw.name
}

resource "azurerm_network_security_rule" "appgw_http_inbound" {
  name                        = "http-inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_appgw.name
}

resource "azurerm_network_security_group" "nsg_was" {
  name                = "nsg-was"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_network_security_rule" "nsr_was_from_appgw" {
  name                        = "allow-from-web"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.websub
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_was.name
}

resource "azurerm_network_security_rule" "nsr_was_lb_probe" {
  name                        = "allow-lb-probe"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_was.name
}

resource "azurerm_network_security_rule" "nsr_was_ssh" {
  name                        = "ssh-bat"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.batsub
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_was.name
}

resource "azurerm_network_security_rule" "nsr_was_to_onprem_mysql" {
  name                        = "allow-mysql-to-onprem"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = var.wassub
  destination_address_prefix  = var.onprem_cidr
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_was.name
}

resource "azurerm_network_security_rule" "nsr_was_to_onprem_elk" {
  name                        = "allow-filebeat-to-elk"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5044"
  source_address_prefix       = var.wassub
  destination_address_prefix  = var.onprem_elk_host
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_was.name
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-db"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_network_security_rule" "nsr_deny_bastion_to_db" {
  name                        = "deny-ssh-from-bastion"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.batsub
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_db.name
}

resource "azurerm_network_security_rule" "nsr_db_from_web" {
  name                        = "allow-from-was"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3306"
  source_address_prefix      = var.wassub
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_db.name
}

resource "azurerm_network_security_rule" "nsr_db_from_onprem" {
  name                        = "allow-mysql-from-onprem"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = var.onprem_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_db.name
}

resource "azurerm_network_security_group" "nsg_bastion" {
  name                = "nsg-bastion"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_network_security_rule" "bastion_in_internet_https" {
  name                        = "allow-https-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_in_gatewaymanager" {
  name                        = "allow-gatewaymanager-inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_in_lb" {
  name                        = "allow-lb-inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_in_hostcomm" {
  name                        = "allow-bastion-host-comm-inbound"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_out_ssh_rdp" {
  name                        = "allow-ssh-rdp-outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_out_azurecloud" {
  name                        = "allow-azurecloud-outbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_out_hostcomm" {
  name                        = "allow-bastion-host-comm-outbound"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}

resource "azurerm_network_security_rule" "bastion_out_getsession" {
  name                        = "allow-getsession-outbound"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.rg_4team.name
  network_security_group_name = azurerm_network_security_group.nsg_bastion.name
}