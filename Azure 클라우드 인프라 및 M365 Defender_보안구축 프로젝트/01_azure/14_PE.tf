resource "azurerm_private_endpoint" "redis_pe_web" {
  name                = "redis-pe-web"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  subnet_id           = azurerm_subnet.web_spoke_PEsub.id

  private_service_connection {
    name                           = "redis-priconn-web"
    private_connection_resource_id = azurerm_managed_redis.redis.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group-web"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis_dns.id]
  }
}