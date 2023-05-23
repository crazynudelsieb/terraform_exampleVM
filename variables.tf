variable "resource_location001" {
  description = "location of the resource."
  type        = string
}

variable "resource_identifier001" {
  description = "identifier refix the resource."
  type        = string
}

variable "resource_status001" {
  description = "status of the resource."
  type        = string
}

variable "vm_name001" {
  description = "name of the vm"
  type        = string
}

variable "vm_name002" {
  description = "name of the vm"
  type        = string
}


variable "vm_adminname001" {
  description = "name of the vm admin user"
  type        = string
}

variable "subscription_id" {
  description = "azure tenant subscription id"
  type        = string
}

variable "client_id" {
  description = "service principal app id"
  type        = string
}

variable "client_secret" {
  description = "service principal password"
  type        = string
}

variable "tenant_id" {
  description = "azure tenant id"
  type        = string
}

variable "md_id" {
  description = "md id"
  type        = string
}

variable "secgrp_id" {
  description = "id for grp.ivp-subcontr_all"
  type        = string
}

variable "kv_enabled_for_deployment" {
  description = "azure key vault enabled for deployment"
  type        = string
}

variable "kv_enabled_for_disk_encryption" {
  description = "azure key vault enabled for disk encryption"
  type        = string
}

variable "kv_enabled_for_template_deployment" {
  description = "azure key vault enabled for template deployment"
  type        = string
}

variable "kv_sku_name" {
  description = "azure key vault sku (standard or premium)"
  type        = string
}

variable "law_sku_name" {
  description = "log analytics workspace sku"
  type        = string
}

variable "vm_sku_name" {
  description = "vm sku"
  type        = string
}