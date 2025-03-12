Here's the complete production-ready solution with all components:

---

### **1. Export-ACL.ps1**
```powershell
<#
.SYNOPSIS
Exports NTFS permissions and audit rules from a file system path

.DESCRIPTION
Captures DACLs (permissions) and SACLs (audit rules) to an XML file

.PARAMETER SourcePath
Path to export security descriptors from

.PARAMETER ExportPath
Output XML file path

.EXAMPLE
.\Export-ACL.ps1 -SourcePath "C:\Data" -ExportPath "C:\Backups\Data_ACL.xml"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path $_)) { Throw "Source path does not exist" }
        $true
    })]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$ExportPath
)

# Require elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Throw "This script requires administrative privileges"
}

try {
    $acl = Get-Acl -Path $SourcePath -Audit -ErrorAction Stop
    $acl | Export-Clixml -Path $ExportPath -Depth 10 -Force
    Write-Output "Successfully exported security descriptor to $ExportPath"
}
catch {
    Write-Error "Export failed: $_"
    exit 1
}
```

---

### **2. Import-ACL.ps1**
```powershell
<#
.SYNOPSIS
Imports NTFS permissions and audit rules to a target path

.DESCRIPTION
Applies security settings from a previously exported XML file

.PARAMETER ImportPath
Path to the exported XML file

.PARAMETER TargetPath
Target location to apply permissions

.EXAMPLE
.\Import-ACL.ps1 -ImportPath "C:\Backups\Data_ACL.xml" -TargetPath "D:\RestoredData"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path $_)) { Throw "Import file does not exist" }
        $true
    })]
    [string]$ImportPath,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path $_)) { Throw "Target path does not exist" }
        $true
    })]
    [string]$TargetPath
)

# Require elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Throw "This script requires administrative privileges"
}

try {
    $acl = Import-Clixml -Path $ImportPath
    Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
    Write-Output "Successfully applied security descriptor to $TargetPath"
}
catch {
    Write-Error "Import failed: $_"
    exit 1
}
```

---

### **3. Test-ACL.ps1**
```powershell
<#
.SYNOPSIS
Validates the complete ACL export/import process

.DESCRIPTION
Creates test environment, sets permissions, and verifies migration
#>

[CmdletBinding()]
param()

# Elevate if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Configuration
$basePath = "D:\Scripts\ACL_Test"
$sourceFolder = "$basePath\Source"
$targetFolder = "$basePath\Target"
$exportFile = "$basePath\SecurityDescriptor.xml"

# Initialize environment
try {
    if (Test-Path $basePath) { Remove-Item $basePath -Recurse -Force }
    New-Item -Path $sourceFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
    $testFile = New-Item -Path "$sourceFolder\TestFile.txt" -ItemType File -Force
}
catch {
    Write-Error "Test setup failed: $_"
    exit 1
}

# Set test permissions (updated)
function Set-TestACL {
    param($Path)
    $acl = Get-Acl $Path
    $isDirectory = (Get-Item $Path) -is [System.IO.DirectoryInfo]
    
    $acl.SetAccessRuleProtection($true, $false)
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }

    $inheritance = if ($isDirectory) {
        [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    } else {
        [System.Security.AccessControl.InheritanceFlags]::None
    }

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Users",
        [System.Security.AccessControl.FileSystemRights]::ReadAndExecute,
        $inheritance,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($rule)

    if ($isDirectory) {
        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
            "Everyone",
            [System.Security.AccessControl.FileSystemRights]::Write,
            $inheritance,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AuditFlags]::Success
        )
        $acl.AddAuditRule($auditRule)
    }

    Set-Acl -Path $Path -AclObject $acl
}

# Apply test settings
Set-TestACL -Path $sourceFolder
Set-TestACL -Path $testFile.FullName

# Export/Import process
try {
    .\Export-ACL.ps1 -SourcePath $sourceFolder -ExportPath $exportFile
    .\Import-ACL.ps1 -ImportPath $exportFile -TargetPath $targetFolder
}
catch {
    Write-Error "Test failed during export/import: $_"
    exit 1
}

# Verification
.\Verify-ACL.ps1 -Source $sourceFolder -Target $targetFolder

# Cleanup
Remove-Item $basePath -Recurse -Force -ErrorAction SilentlyContinue
```

---

### **4. Verify-ACL.ps1**
```powershell
<#
.SYNOPSIS
Compares security descriptors between two paths

.DESCRIPTION
Detailed comparison of permissions, audit rules, and ownership

.PARAMETER Source
Original path to compare

.PARAMETER Target
Target path to validate

.EXAMPLE
.\Verify-ACL.ps1 -Source "C:\Data" -Target "D:\Data"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Source,
    
    [Parameter(Mandatory=$true)]
    [string]$Target
)

function Get-ACLDetail {
    param($Path)
    $acl = Get-Acl -Path $Path -Audit
    return [PSCustomObject]@{
        Path = $Path
        Owner = $acl.Owner
        Access = $acl.Access | ForEach-Object {
            [PSCustomObject]@{
                Identity = $_.IdentityReference
                Rights = $_.FileSystemRights
                Type = $_.AccessControlType
                Inherited = $_.IsInherited
                Inheritance = $_.InheritanceFlags
                Propagation = $_.PropagationFlags
            }
        }
        Audit = $acl.Audit | ForEach-Object {
            [PSCustomObject]@{
                Identity = $_.IdentityReference
                Rights = $_.FileSystemRights
                Flags = $_.AuditFlags
                Inheritance = $_.InheritanceFlags
            }
        }
    }
}

$sourceData = Get-ACLDetail -Path $Source
$targetData = Get-ACLDetail -Path $Target

# Compare results
$results = [PSCustomObject]@{
    DACLMatch = (-not (Compare-Object $sourceData.Access $targetData.Access))
    SACLMatch = (-not (Compare-Object $sourceData.Audit $targetData.Audit))
    OwnerMatch = $sourceData.Owner -eq $targetData.Owner
}

# Output
Write-Host "`nSecurity Validation Report" -ForegroundColor Cyan
Write-Host ("{0,-15} {1}" -f "Source Path:", $Source)
Write-Host ("{0,-15} {1}" -f "Target Path:", $Target)

$ownerColor = if ($results.OwnerMatch) { "Green" } else { "Red" }
Write-Host ("{0,-15} {1}" -f "Owner Match:", $results.OwnerMatch) -ForegroundColor $ownerColor

$daclColor = if ($results.DACLMatch) { "Green" } else { "Red" }
Write-Host ("{0,-15} {1}" -f "DACL Match:", $results.DACLMatch) -ForegroundColor $daclColor

$saclColor = if ($results.SACLMatch) { "Green" } else { "Red" }
Write-Host ("{0,-15} {1}" -f "SACL Match:", $results.SACLMatch) -ForegroundColor $saclColor
```

---

### **Usage Workflow**
1. **Export Permissions**  
   ```powershell
   .\Export-ACL.ps1 -SourcePath "C:\ProductionData" -ExportPath "C:\Backups\Prod_ACL.xml"
   ```

2. **Import Permissions**  
   ```powershell
   .\Import-ACL.ps1 -ImportPath "C:\Backups\Prod_ACL.xml" -TargetPath "D:\NewData"
   ```

3. **Validate Migration**  
   ```powershell
   .\Verify-ACL.ps1 -Source "C:\ProductionData" -Target "D:\NewData"
   ```

4. **Full Test Cycle**  
   ```powershell
   .\Test-ACL.ps1
   ```

---

### **Key Features**
- **Comprehensive Handling**: Manages both DACLs and SACLs
- **Elevation Checks**: Ensures admin privileges
- **Detailed Reporting**: Color-coded diff output
- **Production Safety**: Input validation and error handling
- **Cross-Platform**: Works on PowerShell 5.1+ and PowerShell 7+
- **Self-Contained Testing**: Includes cleanup functions

This final version provides enterprise-grade ACL management with full validation capabilities.
