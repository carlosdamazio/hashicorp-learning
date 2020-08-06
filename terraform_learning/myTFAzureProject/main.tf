# Resource group
resource "azurerm_resource_group" "rg" {
    name     = "myTFResourceGroup"
    location = "brazilsouth"

    tags = {
        Environment = "Terraform Getting Started again"
        Team = "DevOps"
    }
}

# Virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "myTFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "brazilsouth"
    resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
    name                 = "myTFSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "publicip" {
    name                = "myTFPublicIP"
    location            = "brazilsouth"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
}

# Network Security Group and its rules
resource "azurerm_network_security_group" "nsg" {
    name                = "myTFNSG"
    location            = "brazilsouth"
    resource_group_name = azurerm_resource_group.rg.name

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
    name                = "myNIC"
    location            = "brazilsouth"
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "myNICConfig"
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
    name                  = "myTFVM"
    location              = "brazilsouth"
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myTFVM"
        admin_username = "damnazio"
        admin_password = "goF1gure"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}