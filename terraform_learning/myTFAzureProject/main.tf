# Resource group
resource "azurerm_resource_group" "rg" {
    name     = "${var.resource_prefix}TFResourceGroup"
    location = var.location
    tags     = var.tags
}

# Virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.resource_prefix}TFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.resource_prefix}TFSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "publicip" {
    name                = "${var.resource_prefix}TFPublicIP"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"
    tags                = var.tags
}

# Network Security Group and its rules
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.resource_prefix}TFNSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Network interface
resource "azurerm_network_interface" "nic" {
    name                = "${var.resource_prefix}NIC"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    ip_configuration {
        name                          = "${var.resource_prefix}NICConfig"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }
}

# Its association
resource "azurerm_network_interface_security_group_association" "nic-nsg" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
    name                  = "${var.resource_prefix}TFVM"
    location              = var.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size               = "Standard_DS1_v2"
    tags                  = var.tags

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = var.sku
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.resource_prefix}TFVM"
        admin_username = var.admin_username
        admin_password = var.admin_password
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

}

data "azurerm_public_ip" "ip" {
    name                = azurerm_public_ip.publicip.name
    resource_group_name = azurerm_virtual_machine.vm.resource_group_name
    depends_on = [azurerm_virtual_machine.vm]
}

output "os_sky" {
    value = lookup(var.sku, var.location)
}

output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address
}
