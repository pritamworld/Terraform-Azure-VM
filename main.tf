provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "lambton" {
  name     = "lambton-resource-group"
  location = "West Europe"
}

resource "azurerm_virtual_network" "lambton" {
  name                = "lambton-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lambton.location
  resource_group_name = azurerm_resource_group.lambton.name
}

resource "azurerm_subnet" "lambton" {
  name                 = "lambton-subnet"
  resource_group_name  = azurerm_resource_group.lambton.name
  virtual_network_name = azurerm_virtual_network.lambton.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "lambton" {
  name                = "lambton-publicip"
  location            = azurerm_resource_group.lambton.location
  resource_group_name = azurerm_resource_group.lambton.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "lambton" {
  name                = "lambton-nsg"
  location            = azurerm_resource_group.lambton.location
  resource_group_name = azurerm_resource_group.lambton.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_app_port"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "lambton" {
  name                = "lambton-nic"
  location            = azurerm_resource_group.lambton.location
  resource_group_name = azurerm_resource_group.lambton.name

  ip_configuration {
    name                          = "lambton-ipconfig"
    subnet_id                     = azurerm_subnet.lambton.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lambton.id
  }

}

resource "azurerm_network_interface_security_group_association" "lambton" {
  network_interface_id      = azurerm_network_interface.lambton.id
  network_security_group_id = azurerm_network_security_group.lambton.id
}

resource "azurerm_virtual_machine" "lambton" {
  name                  = "lambton-vm"
  location              = azurerm_resource_group.lambton.location
  resource_group_name   = azurerm_resource_group.lambton.name
  network_interface_ids = [azurerm_network_interface.lambton.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "lambton-osdisk"
    caching           = "ReadWrite"
    create_option    = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "lambtonvm"
    admin_username = "adminuser"
    admin_password = "adminpasswordG3#"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "instance_ip" {
  value = azurerm_public_ip.lambton.ip_address
}