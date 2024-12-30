plugin "azure" {
  enabled = true
}

rule "no-empty-values" {
  enabled = true
}

rule "variable-naming" {
  enabled      = true
  name_pattern = "^[a-z_][a-z0-9_]*$"
}
