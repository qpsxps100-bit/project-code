resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {

  name                = "web-vmss"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location

  instances      = 1
  sku            = "Standard_B2s"
  admin_username = "team4"
  upgrade_mode = "Manual"
  custom_data = sensitive(
    base64encode(
      templatefile("${path.module}/web_vmss.sh", {
        waslbip = var.waslbip
        github_user   = var.github_user
        github_repo   = var.github_repo
        github_branch = var.github_branch
        github_token  = var.github_token

      })
    )
  )
  depends_on = [
    azurerm_firewall.hub_fw,
    azurerm_subnet_route_table_association.web_rt_asso
  ]

  admin_ssh_key {
    username   = "team4"
    public_key = file("${path.module}/id_rsa.pub")
  }
  
  lifecycle {
    ignore_changes = [
      instances
    ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
    version   = "9.8.20260525"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-lvm"
  }

  network_interface {

    name                       = "web-vmssnic"
    primary                    = true
    network_security_group_id = azurerm_network_security_group.nsg_web.id


    ip_configuration {

      name      = "web-vmss-ip"
      primary   = true
      subnet_id = azurerm_subnet.web_spoke_websub.id
      application_gateway_backend_address_pool_ids = [
        one(
          azurerm_application_gateway.appgw.backend_address_pool[*].id
        )
      ]
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "was_vmss" {
  name                = "was-vmss"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  instances      = 1
  sku            = "Standard_B2s"
  admin_username = "team4"
  upgrade_mode = "Manual"
  custom_data = sensitive(
    base64encode(
      templatefile("${path.module}/was_vmss.sh", {
        mysql_admin_username = var.mysql_admin_username
        mysql_admin_password = var.mysql_admin_password
        onprem_mysql_host = var.onprem_mysql_host
        azure_mysql_fqdn = (azurerm_mysql_flexible_server.mysql.fqdn)
        redis_host = (azurerm_managed_redis.redis.hostname)
        redis_key = urlencode(azurerm_managed_redis.redis.default_database[0].primary_access_key)
        redis_port = (azurerm_managed_redis.redis.default_database[0].port)
        elk_ip = var.onprem_elk_host
        github_user   = var.github_user
        github_repo   = var.github_repo
        github_branch = var.github_branch
        github_token  = var.github_token
        app_db_name = var.app_db_name
        app_db_user = var.app_db_user
      })
    )
  )
  depends_on = [
    azurerm_firewall.hub_fw,
    azurerm_subnet_route_table_association.was_rt_asso
  ]

  admin_ssh_key {
    username   = "team4"
    public_key = file("${path.module}/id_rsa.pub")
  }

  lifecycle {
    ignore_changes = [
      instances
    ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-lvm"
    version   = "9.8.20260525"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-lvm"
  }

  network_interface {

    name                       = "was-vmssnic"
    primary                    = true
    network_security_group_id = azurerm_network_security_group.nsg_was.id


    ip_configuration {
      name      = "was-vmss-ip"
      primary   = true
      subnet_id = azurerm_subnet.web_spoke_wassub.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.was_lb_backend.id
      ]
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}