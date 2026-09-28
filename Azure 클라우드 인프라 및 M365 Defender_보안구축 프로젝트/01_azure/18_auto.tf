resource "azurerm_monitor_autoscale_setting" "auto" {
  name = "team4-auto"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  target_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
  enabled = true
  profile {
    name = "team4-profile"
    capacity {
        default = 2
        minimum = 1
        maximum = 6
    }
    rule {
        metric_trigger {
            metric_name = "Percentage CPU"
            metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
            time_grain = "PT1M"
            statistic = "Average"
            time_window = "PT5M"
            time_aggregation = "Average"
            operator = "GreaterThanOrEqual"
            threshold = 70
        }
        scale_action {
            direction = "Increase"
            type = "ChangeCount"
            value = "1"
            cooldown = "PT5M"
        }
    }
    rule {
        metric_trigger {
            metric_name = "Percentage CPU"
            metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
            time_grain = "PT1M"
            statistic = "Average"
            time_window = "PT5M"
            time_aggregation = "Average"
            operator = "LessThanOrEqual"
            threshold = 20
        }
        scale_action {
            direction = "Decrease"
            type = "ChangeCount"
            value = "1"
            cooldown = "PT5M"
        }
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "was_auto" {
  name                = "team4-was-auto"
  resource_group_name = azurerm_resource_group.rg_4team.name
  location            = azurerm_resource_group.rg_4team.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.was_vmss.id
  enabled              = true

  profile {
    name = "team4-was-profile"
    capacity {
      default = 1
      minimum = 1
      maximum = 6
    }

    rule {
      metric_trigger {
        metric_name         = "Percentage CPU"
        metric_resource_id  = azurerm_linux_virtual_machine_scale_set.was_vmss.id
        time_grain          = "PT1M"
        statistic            = "Average"
        time_window          = "PT5M"
        time_aggregation     = "Average"
        operator              = "GreaterThanOrEqual"
        threshold             = 70
      }
      scale_action {
        direction = "Increase"
        type       = "ChangeCount"
        value       = "1"
        cooldown    = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name         = "Percentage CPU"
        metric_resource_id  = azurerm_linux_virtual_machine_scale_set.was_vmss.id
        time_grain          = "PT1M"
        statistic            = "Average"
        time_window          = "PT5M"
        time_aggregation     = "Average"
        operator              = "LessThanOrEqual"
        threshold             = 20
      }
      scale_action {
        direction = "Decrease"
        type       = "ChangeCount"
        value       = "1"
        cooldown    = "PT5M"
      }
    }
  }
}