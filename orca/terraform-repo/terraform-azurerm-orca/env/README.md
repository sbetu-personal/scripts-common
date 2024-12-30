# Environment Configuration

This directory contains environment-specific configurations for dev, prod, etc.

Usage:
  $ cd ../orca
  $ terraform init
  $ terraform plan -var-file="../env/dev.tfvars"
  $ terraform apply -var-file="../env/dev.tfvars"
