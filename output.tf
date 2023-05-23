output "rg001_name" {
  value = azurerm_resource_group.rg001.name
}

output "keyvault_name" {
  value = azurerm_key_vault.kv001.name
}
##########################
#vm
##########################
output "vm_name" {
  value = azurerm_windows_virtual_machine.vm001.name
}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.vm001.public_ip_address
}

output "vm_admin_user_name" {
  value = var.vm_adminname001
}

output "vm_admin_pw" {
  value     = azurerm_key_vault_secret.vmpw001.value
  sensitive = true
}

output "vm_admin_pw_secret_name" {
  value = azurerm_key_vault_secret.vmpw001.name
}