variable "name" {
  type        = string
  description = "Name of the route table."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of routes."
}
