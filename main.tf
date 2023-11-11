# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Provides the Resource group to Logically contain resources
resource"azurerm_resource_group" "rg"{
    name      = "seneca_dev"
    location  = "Canada East"
    tags      = {
      environment  = "dev"
      source       = "Terraform"
    }
}

#VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "seneca_dev-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#Dev subnet
resource "azurerm_subnet" "subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.10.0/24"]
}



#NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "dev-SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDPtoServer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    #source_address_prefix      = "10.0.20.0/24"
    #destination_address_prefix = "*"
    destination_address_prefix = "10.0.10.0/24"
  }


  security_rule {
    name                       = "AllowHTTPConnection"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    #source_address_prefix      = "10.0.20.0/24"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.10.0/24"
  }
  tags = {
    environment = "Dev"
  }


  
}

#Public IP Adress
resource "azurerm_public_ip" "PIP" {
  name                = "dev-PIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  #idle_timeout_in_minutes = 30

  tags = {
    environment = "Dev"
  }
}

#NIC Network Interfacec
resource "azurerm_network_interface" "nic" {
  name                = "seneca_dev-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address_allocation = "Static"
    #private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.PIP.id
  }
}


#NSG Association to NIC
resource "azurerm_network_interface_security_group_association" "nsg-nic-association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "dev-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}