Here’s how you can represent the NSG rules from the script in **`tfvars` format** for use with Terraform:

```hcl
nsg_rules = [
  {
    name                   = "collector-https-rule"
    priority               = 100
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_address_prefix  = "*"
    source_port_range      = "*"
    destination_address_prefix = "10.20.30.40" # Replace with actual private endpoint IP or CIDR
    destination_port_range = "443"
  },
  {
    name                   = "collector-vnet-outbound-rule"
    priority               = 120
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_address_prefix  = "VirtualNetwork"
    source_port_range      = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range = "*"
  },
  {
    name                   = "collector-deny-rule"
    priority               = 150
    direction              = "Outbound"
    access                 = "Deny"
    protocol               = "*"
    source_address_prefix  = "*"
    source_port_range      = "*"
    destination_address_prefix = "*"
    destination_port_range = "*"
  }
]
```

### Explanation of Fields:
- **`name`**: Name of the rule.
- **`priority`**: Priority of the rule (lower priority takes precedence).
- **`direction`**: Direction of the traffic (`Outbound` or `Inbound`).
- **`access`**: Action to take (`Allow` or `Deny`).
- **`protocol`**: Protocol to match (e.g., `Tcp`, `Udp`, or `*` for all).
- **`source_address_prefix`**: Source address or range. Use `"*"` for any.
- **`source_port_range`**: Source port. Use `"*"` for any.
- **`destination_address_prefix`**: Destination address or range. Replace `"*"` with specific IP(s) if needed.
- **`destination_port_range`**: Destination port. Use `"443"` for HTTPS traffic.

### How to Use:
You can reference this variable in your Terraform configuration for creating NSG rules dynamically. For example:

```hcl
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = var.location
  resource_group_name = var.resource_group
}

resource "azurerm_network_security_rule" "example" {
  for_each = var.nsg_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_address_prefix       = each.value.source_address_prefix
  source_port_range           = each.value.source_port_range
  destination_address_prefix  = each.value.destination_address_prefix
  destination_port_range      = each.value.destination_port_range
  network_security_group_name = azurerm_network_security_group.example.name
}
```

Replace `"10.20.30.40"` in the `destination_address_prefix` with the correct private endpoint IP(s) or CIDR block when it’s confirmed by the vendor.

Let me know if you need further customization!
