provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "moxdroid" {
  name     = "moxdroid-resource-group"
  location = "West Europe"
}

resource "azurerm_virtual_network" "moxdroid" {
  name                = "moxdroid-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.moxdroid.location
  resource_group_name = azurerm_resource_group.moxdroid.name
}

resource "azurerm_subnet" "moxdroid" {
  name                 = "moxdroid-subnet"
  resource_group_name  = azurerm_resource_group.moxdroid.name
  virtual_network_name = azurerm_virtual_network.moxdroid.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "moxdroid" {
  name                = "moxdroid-publicip"
  location            = azurerm_resource_group.moxdroid.location
  resource_group_name = azurerm_resource_group.moxdroid.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "moxdroid" {
  name                = "moxdroid-nsg"
  location            = azurerm_resource_group.moxdroid.location
  resource_group_name = azurerm_resource_group.moxdroid.name

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

resource "azurerm_network_interface" "moxdroid" {
  name                = "moxdroid-nic"
  location            = azurerm_resource_group.moxdroid.location
  resource_group_name = azurerm_resource_group.moxdroid.name

  ip_configuration {
    name                          = "moxdroid-ipconfig"
    subnet_id                     = azurerm_subnet.moxdroid.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.moxdroid.id
  }

}

resource "azurerm_network_interface_security_group_association" "moxdroid" {
  network_interface_id      = azurerm_network_interface.moxdroid.id
  network_security_group_id = azurerm_network_security_group.moxdroid.id
}

resource "azurerm_virtual_machine" "moxdroid" {
  name                  = "moxdroid-vm"
  location              = azurerm_resource_group.moxdroid.location
  resource_group_name   = azurerm_resource_group.moxdroid.name
  network_interface_ids = [azurerm_network_interface.moxdroid.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "moxdroid-osdisk"
    caching           = "ReadWrite"
    create_option    = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "moxdroidvm"
    admin_username = "adminuser"
    admin_password = "adminpasswordG3#"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "instance_ip" {
  value = azurerm_public_ip.moxdroid.ip_address
}