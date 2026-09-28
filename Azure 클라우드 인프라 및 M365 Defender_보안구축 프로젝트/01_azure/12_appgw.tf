resource "azurerm_application_gateway" "appgw" {
  name                = "app-gw"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf_policy.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-conf"
    subnet_id = azurerm_subnet.hub_appgwsub.id
  }

  frontend_ip_configuration {
    name                 = "appgw-ip-frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

 probe {
  name                = "web-probe"
  protocol            = "Http"
  path                = "/health.html"
  interval            = 30
  timeout             = 10
  unhealthy_threshold = 3
  host                = "127.0.0.1"
}

  backend_address_pool {
    name = "backend"
  }

  backend_http_settings {
    name                  = "backend-http"
    cookie_based_affinity = "Enabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "web-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-ip-frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rtrule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend"
    backend_http_settings_name = "backend-http"
    priority                   = 100
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "waf-policy"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}