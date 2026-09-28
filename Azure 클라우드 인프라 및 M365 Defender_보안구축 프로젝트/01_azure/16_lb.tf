resource "azurerm_lb" "was_lb" {
  name                = "was-lb"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "was-lb-frontend"
    subnet_id                     = azurerm_subnet.web_spoke_wassub.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.waslbip
  }
}

resource "azurerm_lb_backend_address_pool" "was_lb_backend" {
  loadbalancer_id = azurerm_lb.was_lb.id
  name            = "was-backend"
}

resource "azurerm_lb_probe" "was_probe" {
  loadbalancer_id = azurerm_lb.was_lb.id
  name            = "was-probe"
  protocol        = "Http"
  port            = 80
  request_path = "/health.php"
}

resource "azurerm_lb_rule" "was_rule" {
  loadbalancer_id                = azurerm_lb.was_lb.id
  name                           = "was-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "was-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.was_lb_backend.id]
  probe_id                       = azurerm_lb_probe.was_probe.id
}