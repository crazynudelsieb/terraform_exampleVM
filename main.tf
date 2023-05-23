resource "random_id" "randomid001" {
  keepers = {
    # Generate a new ID only when a new identifier is set
    identifier = var.resource_identifier001
  }
  byte_length = 3
}

#resource "time_sleep" "wait_180_seconds" {
#  depends_on = [azurerm_windows_virtual_machine.vm001]
#
#  create_duration = "30s"
#}

#rg for core ressources
resource "azurerm_resource_group" "rg001" {
  location = var.resource_location001
  name     = join("-", ["rg001", var.resource_identifier001, random_id.randomid001.hex])
  tags     = local.tags
}

resource "azurerm_key_vault" "kv001" {
  name                            = join("-", ["kv001", var.resource_identifier001, random_id.randomid001.hex])
  location                        = azurerm_resource_group.rg001.location
  resource_group_name             = azurerm_resource_group.rg001.name
  enabled_for_deployment          = var.kv_enabled_for_deployment
  enabled_for_disk_encryption     = var.kv_enabled_for_disk_encryption
  enabled_for_template_deployment = var.kv_enabled_for_template_deployment
  tenant_id                       = var.tenant_id
  sku_name                        = var.kv_sku_name
  tags                            = local.tags

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = var.secgrp_id
    key_permissions         = ["Create", "Get", "List", "Purge", "Recover", "Delete"]
    secret_permissions      = ["Get", "List", "Purge", "Recover", "Set", "Delete"]
    certificate_permissions = ["Create", "Get", "List", "Purge", "Recover", "Update", "Delete"]
  }

  depends_on = [azurerm_resource_group.rg001]
}

#Create KeyVault VM password
resource "random_password" "vmpwvalue001" {
  keepers = {
    # Generate a new PW when the identifier changes
    identifier = var.resource_identifier001
  }
  length  = 32
  special = true

}

#Create VM Admin PW in KV
resource "azurerm_key_vault_secret" "vmpw001" {
  name         = join("-", ["pw001", var.resource_identifier001, random_id.randomid001.hex])
  value        = random_password.vmpwvalue001.result
  key_vault_id = azurerm_key_vault.kv001.id
  depends_on   = [azurerm_key_vault.kv001]
}

# Create virtual network
resource "azurerm_virtual_network" "vnet001" {
  name                = join("-", ["vnet001", var.resource_identifier001, random_id.randomid001.hex])
  address_space       = ["10.69.69.0/24"]
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  tags                = local.tags
}

# Create subnet for vms
resource "azurerm_subnet" "snet011" {
  name                 = join("-", ["snet011", var.resource_identifier001, random_id.randomid001.hex])
  resource_group_name  = azurerm_resource_group.rg001.name
  virtual_network_name = azurerm_virtual_network.vnet001.name
  address_prefixes     = ["10.69.69.0/28"]
}

# Create subnet for bastion
resource "azurerm_subnet" "snet012" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg001.name
  virtual_network_name = azurerm_virtual_network.vnet001.name
  address_prefixes     = ["10.69.69.32/28"]
}


# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg001" {
  name                = join("-", ["nsg001", var.resource_identifier001, random_id.randomid001.hex])
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  tags                = local.tags

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Create public IPs
resource "azurerm_public_ip" "pip001" {
  name                = join("-", ["pip001", var.resource_identifier001, random_id.randomid001.hex])
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  allocation_method   = "Static"
  tags                = local.tags
}

# Create network interface
resource "azurerm_network_interface" "nic001" {
  name                = join("-", ["nic001", var.resource_identifier001, random_id.randomid001.hex])
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  tags                = local.tags

  ip_configuration {
    name                          = join("-", ["ipc001", var.resource_identifier001, random_id.randomid001.hex])
    subnet_id                     = azurerm_subnet.snet011.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip001.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nicnsg001association001" {
  network_interface_id      = azurerm_network_interface.nic001.id
  network_security_group_id = azurerm_network_security_group.nsg001.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diagnostics001" {
  name                     = join("", ["diag001", var.resource_identifier001, random_id.randomid001.hex])
  location                 = azurerm_resource_group.rg001.location
  resource_group_name      = azurerm_resource_group.rg001.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_log_analytics_workspace" "la001" {
  name                = join("-", ["la001", var.resource_identifier001, random_id.randomid001.hex])
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "vm001" {
  name                  = join("-", ["vm001", var.resource_identifier001, random_id.randomid001.hex])
  computer_name         = var.vm_name001
  admin_username        = var.vm_adminname001
  admin_password        = azurerm_key_vault_secret.vmpw001.value
  location              = azurerm_resource_group.rg001.location
  resource_group_name   = azurerm_resource_group.rg001.name
  network_interface_ids = [azurerm_network_interface.nic001.id]
  size                  = var.vm_sku_name
  tags                  = local.tags
  #hotpatching curently only supported by:
  #2022-datacenter-azure-edition-core
  #2022-datacenter-azure-edition-core-smalldisk
  #hotpatching_enabled      = true
  license_type = "Windows_Server"
  #enable_automatic_updates = true
  #patch_mode               = "AutomaticByPlatform"
  #patch_assessment_mode    = "AutomaticByPlatform"

  provision_vm_agent  = true
  secure_boot_enabled = true
  timezone            = "W. Europe Standard Time"
  #priority                 = "Spot"
  #eviction_policy          = "Deallocate"

  os_disk {
    name                 = join("-", ["disk001", var.resource_identifier001, random_id.randomid001.hex])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagnostics001.primary_blob_endpoint
  }
}

#PS Extension
resource "azurerm_virtual_machine_extension" "vme001" {
  name                       = "GuestAccount"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm001.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
            "fileUris": [
                "https://raw.githubusercontent.com/crazynudelsieb/azure_script_test/main/guestuser.ps1"
                ],
            "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File guestuser.ps1"
    }
  SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_shutdown_schedule001" {
  virtual_machine_id    = azurerm_windows_virtual_machine.vm001.id
  location              = azurerm_resource_group.rg001.location
  enabled               = true
  daily_recurrence_time = "1500"
  timezone              = "Central Europe Standard Time"
  tags                  = local.tags

  notification_settings {
    enabled = true
    email   = "michael.dima@a1.at"
  }
}

resource "azurerm_virtual_machine_extension" "ama001" {
  name                       = join("-", ["ama001", var.resource_identifier001, random_id.randomid001.hex])
  virtual_machine_id         = azurerm_windows_virtual_machine.vm001.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = "true"
  depends_on                 = [azurerm_windows_virtual_machine.vm001, azurerm_log_analytics_workspace.la001]

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}
resource "azurerm_virtual_machine_extension" "agc001" {
  name                       = "AzurePolicyforWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm001.id
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = "true"
}

resource "azurerm_policy_virtual_machine_configuration_assignment" "assignment001" {
  name               = "AzureWindowsBaseline"
  location           = azurerm_windows_virtual_machine.vm001.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm001.id

  configuration {
    assignment_type = "ApplyAndAutoCorrect"
    version         = "1.*"
    parameter {
      name  = "Minimum password length;ExpectedValue"
      value = "16"
    }
    parameter {
      name  = "Minimum password length;RemediateValue"
      value = "16"
    }
    parameter {
      name  = "Enforce password history;ExpectedValue"
      value = "32"
    }
    parameter {
      name  = "Enforce password history;RemediateValue"
      value = "32"
    }
  }
}

#resource "azurerm_public_ip" "pip002" {
#  name                = join("-", ["pip002", var.resource_identifier001, random_id.randomid001.hex])
#  location            = azurerm_resource_group.rg001.location
#  resource_group_name = azurerm_resource_group.rg001.name
#  allocation_method   = "Static"
#  sku                 = "Standard"
#}

#resource "azurerm_bastion_host" "bastion0001" {
#  name                = join("-", ["bastion001", var.resource_identifier001, random_id.randomid001.hex])
#  location            = azurerm_resource_group.rg001.location
#  resource_group_name = azurerm_resource_group.rg001.name

#  ip_configuration {
#    name                 = join("-", ["ipc002", var.resource_identifier001, random_id.randomid001.hex])
#    subnet_id            = azurerm_subnet.snet012.id
#    public_ip_address_id = azurerm_public_ip.pip002.id
#  }
#}

resource "azurerm_monitor_data_collection_rule" "amarule1" {
  name                = join("-", ["amarule001", var.resource_identifier001, random_id.randomid001.hex])
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  depends_on          = [azurerm_virtual_machine_extension.ama001]
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.la001.id
      name                  = "log-analytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["log-analytics"]
  }

  data_sources {
    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = ["Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
      "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"]
      name = "eventLogsDataSource"
    }
  }
}

# data collection rule association

resource "azurerm_monitor_data_collection_rule_association" "dcra001" {
  name                    = join("-", ["dcra001", var.resource_identifier001, random_id.randomid001.hex])
  target_resource_id      = azurerm_windows_virtual_machine.vm001.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.amarule1.id
}
