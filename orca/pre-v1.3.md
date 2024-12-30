In **azurerm v4.x** and later, associating a subnet with an NSG or a route table requires using separate resources:

- `azurerm_subnet_network_security_group_association`
- `azurerm_subnet_route_table_association`

You also can’t directly reference a value that might be unknown at plan time for `count` (e.g., `network_security_group_id` coming from another module or resource). This often triggers the “Invalid count argument” or “Cycle or unknown value” error.

Below are **two** approaches to handle this:

---

## 1) Use Single Resources Without `count` or `for_each` (Requires Non-Null IDs)

If your `var.network_security_group_id` (or route table ID) will **always** be known and non-null when you run `terraform plan`, you can write a straightforward resource:

```hcl
resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = var.network_security_group_id
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.this.id
  route_table_id = var.route_table_id
}
```

**Caveat**: If `var.network_security_group_id` is `null` or depends on something that isn’t known until after plan time, you’ll get errors. In that case, see approach #2.

---

## 2) Use `for_each` with a Conditional Map (Allows Optional/Unknown Values)

If you want these associations to be **optional** or your ID variables might be **unknown** at plan time, replace `count` with `for_each` and conditionally create zero or one resource:

### Subnet Module

```hcl
resource "azurerm_subnet" "this" {
  name                 = var.name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.address_prefixes
  service_endpoints    = var.service_endpoints
}

locals {
  # If NSG is null, create an empty map; if it's present, create a map with one entry
  nsg_ids = var.network_security_group_id == null
    ? {}
    : { "nsg" = var.network_security_group_id }

  # Same idea for route table
  route_table_ids = var.route_table_id == null
    ? {}
    : { "rt" = var.route_table_id }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.nsg_ids

  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = each.value
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.route_table_ids

  subnet_id      = azurerm_subnet.this.id
  route_table_id = each.value
}
```

### Variables

```hcl
variable "network_security_group_id" {
  type        = string
  description = "Optional ID of the NSG to associate with the subnet."
  default     = null
}

variable "route_table_id" {
  type        = string
  description = "Optional ID of the route table to associate with the subnet."
  default     = null
}
```

With the **for_each** approach:

- If `network_security_group_id` is `null`, then `nsg_ids` is `{}`, and Terraform will create **no** NSG association resource.
- If `network_security_group_id` is non-null (and known at plan time), Terraform will create **one** resource.
- Likewise for `route_table_id`.

**Advantages**  
- Allows either “0 or 1” resource creation in a single pass without having to use `target` or `depends_on`.
- Avoids “Invalid count argument” errors if the ID is unknown at plan time.
- Works well when these IDs are optional or come from other modules.

---

## Why Not `count` with Conditionals?

If you do something like:

```hcl
count = var.network_security_group_id == null ? 0 : 1
```

…and `network_security_group_id` is computed by another resource or module, Terraform may say `Error: Invalid count argument (unknown at plan time)` because it can’t evaluate that expression before the plan.  

Using a **`for_each` with a conditional map** is typically more robust in these scenarios because Terraform can handle unknown values more gracefully than with direct `count` references.

---

## TL;DR

1. **If IDs are always non-null and known at plan time**: Just reference them directly in single resources without `count/for_each`.  
2. **If IDs may be null or unknown at plan time**: Use the **`for_each` with a conditional map** approach.  

That’s it! By following approach #2, you can create these associations **without** the “Invalid count argument” error and **without** using `depends_on` or `-target`.