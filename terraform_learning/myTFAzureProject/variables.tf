variable "location" {}

variable "admin_username" {
    type        = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type        = string
    description = "Password must meet Azure complexity requirements"
}

variable "resource_prefix" {
    type    = string
    default = "my"
}

variable "tags" {
    type = map

    default ={
        Environment = "Terraform GS"
        Dept = "Engineering"
    }
}

variable "sku" {
    default = {
        westus2 = "16.04-LTS"
        brazilsouth = "18.04-LTS"
    }
}
