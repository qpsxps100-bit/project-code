resource "azurerm_firewall_policy" "hub_fw_policy" {
  name                = "hub-fw-policy"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
}

resource "azurerm_firewall_policy_rule_collection_group" "hub_fwrule" {
  name               = "hub-fwrule"
  firewall_policy_id = azurerm_firewall_policy.hub_fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allow-outbound"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-http-https-web"
      protocols             = ["TCP"]
      source_addresses      = [var.webspokecidr]
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }

    rule {
      name                  = "allow-dns-web"
      protocols             = ["UDP", "TCP"]
      source_addresses      = [var.webspokecidr]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
    }
  }