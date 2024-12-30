variable "name" {
  type        = string
  description = "Name of the network security group."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "List of security rules."
}
