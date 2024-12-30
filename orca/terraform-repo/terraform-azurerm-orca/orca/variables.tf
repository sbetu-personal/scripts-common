variable "vnet_name" {
  type        = string
  description = "Name of the VNet."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space of the VNet."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VNet."
  default     = []
}

variable "nsg_name" {
  type        = string
  description = "Name of the network security group."
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
  description = "Security rules for the network security group."
}

variable "route_table_name" {
  type        = string
  description = "Name of the route table."
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "Routes for the route table."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet."
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet."
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints for the subnet."
  default     = []
}
