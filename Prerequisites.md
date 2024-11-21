## Prerequisites

Before you begin, ensure you have the following installed and configured on your local machine:

### Essential Tools

1. **Git**: Version control system for cloning repositories and managing code.
   - Install from [git-scm.com](https://git-scm.com/downloads).

2. **Git Bash** (for Windows users): Provides a Bash emulation to run Git from the command line.
   - Included with Git for Windows.

3. **Python 3**: Required for installing pre-commit and other Python-based tools.
   - Download from [python.org](https://www.python.org/downloads/).

4. **Terraform CLI**: Version 1.0.0 or higher, for managing infrastructure as code.
   - Install from [terraform.io](https://www.terraform.io/downloads).
   - **Alternative**: [OpenTofu](https://opentofu.org/) can be used as an open-source alternative to Terraform.

5. **Azure CLI**: For authentication and managing Azure resources.
   - Install from [docs.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).

6. **Pre-commit**: Framework for managing and maintaining multi-language pre-commit hooks.
   - Install via pip:
     ```bash
     pip install pre-commit
     ```

### Tools Required for Pre-Commit Hooks

Our pre-commit configuration includes several hooks that require additional tools to be installed:

1. **TFLint**: Linter for Terraform code.
   - **Required for**: `terraform_tflint` hook.
   - Install from [tflint.io](https://github.com/terraform-linters/tflint#installation).

2. **TFsec**: Static analysis security scanner for Terraform code.
   - **Required for**: `terraform_tfsec` hook.
   - Install from [aquasecurity.github.io/tfsec](https://aquasecurity.github.io/tfsec/v1.28.1/).

3. **Terraform Docs**: Tool for generating documentation from Terraform modules.
   - **Version**: 0.12.0 or higher.
   - **Required for**: `terraform_docs` hook.
   - Install from [terraform-docs.io](https://terraform-docs.io/user-guide/installation/).

4. **Checkov**: Static code analysis tool for infrastructure-as-code.
   - **Required for**: `terraform_checkov` hook.
   - Install via pip:
     ```bash
     pip install checkov
     ```

5. **Terragrunt**: Wrapper for Terraform that provides extra tools for working with multiple Terraform modules.
   - **Required for**: `terragrunt_validate` and `terragrunt_valid_inputs` hooks.
   - Install from [terragrunt.gruntwork.io](https://terragrunt.gruntwork.io/docs/getting-started/install/).

6. **Terrascan**: Static code analyzer for Infrastructure as Code.
   - **Required for**: `terrascan` hook.
   - Install from [terrascan.io](https://runterrascan.io/docs/getting-started/installation/).

7. **Trivy**: Vulnerability scanner for containers and other artifacts, including IaC files.
   - **Required for**: `terraform_trivy` hook.
   - Install from [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/v0.41.0/installation/).

8. **Infracost**: Cloud cost estimates for Terraform.
   - **Required for**: `infracost_breakdown` hook.
   - Install from [infracost.io](https://www.infracost.io/docs/#quick-start).

9. **jq**: Command-line JSON processor.
   - **Required for**:
     - `terraform_validate` with the `--retry-once-with-cleanup` flag.
     - `infracost_breakdown` hook.
   - Install from [stedolan.github.io/jq](https://stedolan.github.io/jq/download/).

10. **tfupdate**: Tool to update Terraform version constraints in your files.
    - **Required for**: `tfupdate` hook.
    - Install from [github.com/minamijoyo/tfupdate](https://github.com/minamijoyo/tfupdate#installation).

11. **hcledit**: Command-line editor for HCL (HashiCorp Configuration Language) files.
    - **Required for**: `terraform_wrapper_module_for_each` hook.
    - Install from [github.com/minamijoyo/hcledit](https://github.com/minamijoyo/hcledit#installation).

### Summary of Installation Commands

Below is a consolidated list of commands to install the required tools:

#### For Windows Users

- **Git and Git Bash**:
  - Download and install from [gitforwindows.org](https://gitforwindows.org/).

- **Python 3**:
  - Download and install from [python.org](https://www.python.org/downloads/windows/).

#### For macOS Users

- **Homebrew** (if not installed):
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- **Install Tools via Homebrew**:
  ```bash
  brew install git python terraform tflint tfsec jq
  brew tap terraform-docs/tap
  brew install terraform-docs
  brew install checkov
  brew install terragrunt
  brew install infracost
  brew install tfupdate
  brew install hcledit
  ```

#### For Linux Users

- **Git**:
  ```bash
  sudo apt-get install git
  ```

- **Python 3**:
  ```bash
  sudo apt-get install python3
  ```

- **Other Tools**:
  - Follow installation instructions from the respective websites provided above.

### Verifying Installations

After installing, verify that each tool is correctly installed by checking its version:

```bash
git --version
python3 --version
terraform version
tflint --version
tfsec --version
terraform-docs --version
checkov --version
terragrunt --version
terrascan version
trivy --version
infracost --version
jq --version
tfupdate --version
hcledit --version
```

### Additional Notes

- **Ensure Compatibility**: Verify that the versions of the installed tools meet the minimum required versions.
- **Environment Variables**: Some tools may require adding their installation directories to your system's `PATH` environment variable.

### Optional Tools

- **Docker**: For containerized deployments or if you prefer using Docker images for consistent environments.

---
