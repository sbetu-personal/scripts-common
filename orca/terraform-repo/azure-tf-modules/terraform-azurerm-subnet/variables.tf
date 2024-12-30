variable "name" {
  type        = string
  description = "Name of the subnet."
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network the subnet belongs to."
}

variable "address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints to associate with the subnet."
  default     = []
}

variable "network_security_group_id" {
  type        = string
  description = "ID of the network security group to associate with the subnet."
  default     = null
}

variable "route_table_id" {
  type        = string
  description = "ID of the route table to associate with the subnet."
  default     = null
}
