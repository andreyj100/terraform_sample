terraform {
  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
backend "azurerm" {

resource_group_name   = "terra-infra-state"

storage_account_name  = "tstatefile"

container_name        = "tstate"

key                   = "sample-state-file.tfstate"

}
}

provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
      resource_group {
        prevent_deletion_if_contains_resources = false
        }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - terraformsample-RG
resource "azurerm_resource_group" "terraformsample-app01-rg" {
  name     = "terraformsample-app01-rg"
  location = "eastus"
}
# Create our Virtual Network - terraformsample-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "terraformsamplevnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "subnetVM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - saterra01
resource "azurerm_storage_account" "saterra01" {
  name                     = "saterra01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "terraformsample"
  }
}
# Create our Azure Storage Account - saterra02
resource "azurerm_storage_account" "saterra02" {
  name                     = "saterra02"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "terraformsample"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "terraformsamplevm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - terraformsample-VM01
resource "azurerm_virtual_machine" "vm01" {
  name                  = "vm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "terraformsamplevm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "vm01"
    admin_username     = "administrador"
    admin_password     = "Password123$"
  }
  os_profile_windows_config {
  }
}
