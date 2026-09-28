resource "azurerm_private_dns_zone" "redis_dns" {
  name                = "privatelink.redis.azure.net"
  resource_group_name = azurerm_resource_group.rg_4team.name
}

resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "team4.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg_4team.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_dns_link_web" {
  name                = "redis-dns-link-web"
  private_dns_zone_id = azurerm_private_dns_zone.redis_dns.id
  virtual_network_id  = azurerm_virtual_network.web_spoke_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                = "mysql-dns-link"
  private_dns_zone_id = azurerm_private_dns_zone.mysql_dns.id
  virtual_network_id  = azurerm_virtual_network.db_spoke_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link_web" {
  name                = "mysql-dns-link-web"
  private_dns_zone_id = azurerm_private_dns_zone.mysql_dns.id
  virtual_network_id  = azurerm_virtual_network.web_spoke_vnet.id
}