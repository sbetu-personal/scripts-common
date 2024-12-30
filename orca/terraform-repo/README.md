# Terraform Repository

This repository houses Terraform configurations, modules, and environment files for Azure resources.

## Structure

- `azure-tf-modules/`: Houses reusable Terraform modules for Azure.
- `terraform-azurerm-orca/`: Contains a working Terraform configuration that utilizes the modules.
- `.gitignore`, `.pre-commit-config.yaml`, `.tflint.hcl`: Various configuration files for Terraform best practices (ignore, linting, pre-commit hooks, etc.).

## Usage

1. Clone the repo.
2. (Optional) Install `tfenv` and switch to the matching Terraform version in `.terraform-version`.
3. Install [Pre-Commit](https://pre-commit.com/) and run `pre-commit install`.
4. Initialize, plan, and apply with your environment of choice, for example:
   ```
   cd terraform-azurerm-orca/orca
   terraform init
   terraform plan -var-file="../env/dev.tfvars"
   terraform apply -var-file="../env/dev.tfvars"
   ```

## Contributing

- Ensure all changes pass `terraform fmt`, `terraform validate`, and `tflint`.
- Document new modules thoroughly in a `README.md` within the module folder.
