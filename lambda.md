PowerShell Scripts to Export and Import NTFS ACLs for Directory Trees

In enterprise environments, it’s often necessary to backup and restore NTFS permissions (ACLs) on entire folder trees. Below are two robust PowerShell scripts — one to export (backup) ACLs and one to import (restore) them — rewritten for production use. These scripts incorporate best practices for recursion, error handling, progress reporting, cross-version compatibility, and proper handling of owners, DACLs, and SACLs.

Features and Improvements
	•	Recursive ACL Export: The export script walks the entire directory tree (including subfolders) to capture ACLs.
	•	Complete Security Descriptor Capture: It records Owner, DACL (permissions), and SACL (audit rules) for each file and folder using Get-Acl -Audit (includes SACL data) ￼.
	•	Binary Security Descriptor Storage: Instead of textual SDDL, it stores the raw security descriptor bytes via .GetSecurityDescriptorBinaryForm() ￼ for fidelity.
	•	Relative Paths: Each ACL entry is stored with a path relative to the source root, making it portable to other destinations.
	•	UNC and Local Path Support: Paths are normalized (trailing backslashes removed, etc.) to handle UNC paths reliably (trailing \ on UNC can cause issues ￼). All cmdlets use -LiteralPath to avoid wildcard interpretation ￼.
	•	Optional Compression: On PowerShell 7+, the export script can compress the XML output (using GZip) to reduce size.
	•	Robust Error Handling: Scripts catch exceptions (e.g. access denied on certain files) and emit clear warnings or errors without halting the entire run.
	•	Progress Indicators: Uses Write-Progress to show real-time progress for large trees, improving usability.
	•	Owner Handling on Restore: The import script carefully applies owners. If setting an original owner fails due to privilege limitations, it falls back to keeping the current owner (with a warning) instead of failing ￼ ￼.
	•	File/Directory Differentiation: Ensures that directory ACLs and file ACLs are handled with the correct .NET objects (using DirectorySecurity vs FileSecurity) to apply the security properly.
	•	Structure Recreation: The import script can recreate missing directories automatically, and (optionally) create empty files for missing file entries (controlled by a switch).
	•	Cross-Version Compatibility: Designed for Windows PowerShell 5.1 and PowerShell 7+. (PowerShell 6 had limited ACL support ￼, so usage on 5.1 or 7+ is recommended.)

Below are the scripts with these features implemented. Each script includes inline comments for clarity and can be saved as Export-TreeAcl.ps1 and Import-TreeAcl.ps1 for use in your environment.

Export-TreeAcl.ps1 – Backup ACLs to XML

<#
.SYNOPSIS
Exports the NTFS ACLs (Owner, DACL, SACL) of all files and folders under a given path to a CLIXML file (optionally compressed).

.DESCRIPTION
Recursively traverses the specified directory (including subdirectories) and retrieves the full security descriptor for each file and folder, including the owner, DACL (access permissions), and SACL (audit rules). The security descriptor is stored in raw binary form for accuracy. The output is a serialized CLIXML file containing each item’s relative path and security descriptor. On PowerShell 7 and above, an option is available to compress the output file using GZip.

.PARAMETER Path
The root directory path to export ACLs from. Can be a local path or UNC path. Trailing backslashes are handled automatically. If the path is not found or not accessible, the script will error out.

.PARAMETER OutputPath
The file path where the ACL backup will be saved (as XML or compressed XML). If not provided, a default file name will be used. (For example, “AclBackup.clixml” in the current directory.)

.PARAMETER Compress
Switch to enable GZip compression of the output CLIXML. Only effective on PowerShell 7+ (Core) where System.IO.Compression is available. The compressed file will have “.gz” appended to the output path.

.EXAMPLE
Export-TreeAcl.ps1 -Path "C:\Data\Projects" -OutputPath "C:\Backup\ProjectsAcl.clixml" -Compress

#>
param(
    [Parameter(Mandatory, Position=0)]
    [string]$Path,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$OutputPath = "$(Get-Date -Format 'yyyyMMdd_HHmmss')-AclBackup.clixml",

    [switch]$Compress
)

# Ensure the path exists and get its full, normalized form
try {
    $baseItem = Get-Item -LiteralPath $Path -ErrorAction Stop
} catch {
    Write-Error "Invalid or inaccessible Path: $Path. $_"
    return
}
$basePath = $baseItem.FullName
# Normalize trailing slashes (except for drive root like 'C:\')
if ($basePath.Length -gt 1 -and $basePath.EndsWith('\')) {
    # For a path like \\server\share\ or C:\, leaving the trailing slash is fine.
    # Otherwise, remove trailing slash to avoid double separators later.
    if (!($basePath -match '^[A-Za-z]:\\$' -or $basePath -match '^\\\\[^\\]+\\[^\\]+\\?$')) {
        $basePath = $basePath.TrimEnd('\')
    }
}

Write-Host "Exporting ACLs under: $basePath" -ForegroundColor Cyan

# Collect all items (directories and files) under the base path, including the base folder itself.
# Use -Force to include hidden/system. Use -ErrorAction to handle access issues.
$allItems = @()
try {
    # Include the base folder itself first
    $allItems += $baseItem
    # Recurse into children
    $allItems += Get-ChildItem -LiteralPath $basePath -Force -Recurse -ErrorAction Stop
} catch {
    Write-Warning "Some items under $basePath could not be accessed (permission denied). They will be skipped."
    # Use SilentlyContinue to gather what we can
    $allItems += Get-ChildItem -LiteralPath $basePath -Force -Recurse -ErrorAction SilentlyContinue
    # Ensure base is included even if above threw early
    if ($allItems -notcontains $baseItem) { $allItems += $baseItem }
}

# Prepare collection for ACL data
$aclEntries = New-Object System.Collections.Generic.List[PSObject]

# Total count for progress bar
$total = $allItems.Count
$counter = 0

foreach ($item in $allItems) {
    $counter++
    # Progress display
    $percent = [math]::Floor(($counter / $total) * 100)
    Write-Progress -Activity "Exporting ACLs" -Status "Processing $counter of $total items (`"$percent%`")" -PercentComplete $percent

    # Compute relative path (relative to base path)
    $fullPath = $item.FullName
    if ($fullPath -eq $basePath) {
        # represent the base folder as "." (current directory)
        $relativePath = '.'
    } else {
        # Remove the base path prefix from the full path
        $relativePath = $fullPath.Substring($basePath.Length)
        if ($relativePath.StartsWith('\')) {
            $relativePath = $relativePath.TrimStart('\')
        }
        if (-not $relativePath) { $relativePath = '.' }
    }

    # Get the ACL including audit (SACL). If we lack privilege for SACL, fall back to just DACL.
    try {
        $aclObject = Get-Acl -LiteralPath $fullPath -Audit -ErrorAction Stop
    } catch {
        if ($_ -and $_.Exception.Message -match 'privilege' -or $_.Exception.Message -match 'Unauthorized') {
            Write-Warning "No audit access for $fullPath – capturing DACL/Owner only (run as Admin to include SACL)."
            try {
                $aclObject = Get-Acl -LiteralPath $fullPath -ErrorAction Stop
            } catch {
                Write-Error "Failed to get ACL for $fullPath: $($_.Exception.Message)"
                continue
            }
        } else {
            Write-Error "Failed to get ACL for $fullPath: $($_.Exception.Message)"
            continue
        }
    }

    # Retrieve raw security descriptor bytes
    $sdBytes = $aclObject.GetSecurityDescriptorBinaryForm()
    # Determine if item is a directory
    $isDir = $item.PSIsContainer

    # Create a PSObject to store the entry (for robust serialization)
    $entry = [PSCustomObject]@{
        RelativePath = $relativePath
        IsDirectory  = $isDir
        SDBytes      = $sdBytes
    }
    $aclEntries.Add($entry) | Out-Null
}

# Export to CLIXML file
try {
    $aclEntries | Export-Clixml -LiteralPath $OutputPath -ErrorAction Stop
    Write-Host "ACL data exported to $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to write CLIXML output file `$OutputPath`: $($_.Exception.Message)"
    return
}

# If compression is requested and running on PS 7+, compress the XML file
if ($Compress) {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $gzipPath = "$OutputPath.gz"
        try {
            # Read the XML content and compress it using GZip
            [byte[]]$xmlBytes = [System.IO.File]::ReadAllBytes($OutputPath)
            $fs = [System.IO.File]::Create($gzipPath)
            $gzipStream = New-Object System.IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Compress)
            $gzipStream.Write($xmlBytes, 0, $xmlBytes.Length)
            $gzipStream.Close(); $fs.Close()
            # Remove the original XML after successful compression
            Remove-Item -LiteralPath $OutputPath -Force
            Write-Host "Compressed output to $gzipPath" -ForegroundColor Green
            $OutputPath = $gzipPath  # update output path reference
        } catch {
            Write-Warning "Compression failed: $($_.Exception.Message). Continuing with uncompressed XML."
        }
    } else {
        Write-Warning "Compression requested, but PowerShell $($PSVersionTable.PSVersion) does not support compression. Skipping."
    }
}

Write-Progress -Activity "Exporting ACLs" -Completed
Write-Host "Export completed. Total items processed: $total. Output file: $OutputPath" -ForegroundColor Cyan

How it works: The export script uses Get-ChildItem -Recurse to iterate through all files and subfolders. For each item, it calls Get-Acl -Audit to get the full security descriptor including audit entries ￼. The security descriptor is converted to a byte array with GetSecurityDescriptorBinaryForm() ￼, and stored along with the item’s relative path and a flag indicating if it’s a directory. All this data is serialized to a CLIXML file using Export-Clixml. Using -LiteralPath for all file operations ensures no wildcard or special character in paths will cause issues ￼. If the -Compress switch is used on PowerShell 7+, the script compresses the XML file using GZip after export (since PS7+ supports the required .NET compression classes). Errors (e.g., inaccessible directories) are caught and reported as warnings so the script can continue. The use of Write-Progress provides a real-time indication of progress.

Import-TreeAcl.ps1 – Restore ACLs from XML Backup

<#
.SYNOPSIS
Imports NTFS ACLs from a backup file and applies them to a target directory tree, optionally recreating missing files/folders.

.DESCRIPTION
Reads a CLIXML file produced by Export-TreeAcl (optionally a GZip-compressed .clixml.gz file) containing NTFS security descriptors. Recreates the directory structure under the target path if necessary, then applies each security descriptor to the corresponding file or folder. Handles owner, DACL, and SACL, using the stored binary security descriptor for exact restoration. If setting the original owner is not permitted (due to privilege restrictions), the ACL is applied without changing the owner (a warning is logged) [oai_citation:10‡serverfault.com](https://serverfault.com/questions/126007/powershell-set-acl-fails#:~:text=You%27re%20obviously%20getting%20this%20error,owner%20of%20an%20object%20to) [oai_citation:11‡superuser.com](https://superuser.com/questions/1819564/whats-the-difference-between-takeown-and-set-acl-for-changing-ownership#:~:text=Changing%20the%20owner%20via%20%60Set,anyways%20in%20almost%20every%20case).

.PARAMETER InputPath
The path to the ACL backup file (CLIXML) to import. If the file is GZip-compressed (ends with .gz), the script will automatically decompress it.

.PARAMETER DestinationPath
The root directory where ACLs will be restored. If this path does not exist, it will be created. The relative paths from the backup will be appended to this destination to recreate the original structure.

.PARAMETER CreateMissingFiles
Switch that indicates missing files should be created as empty files (so that their ACLs can be applied). If not specified, any ACL entry for a file that doesn’t exist will be skipped (with a warning). Missing directories are always created.

.EXAMPLE
Import-TreeAcl.ps1 -InputPath "C:\Backup\ProjectsAcl.clixml.gz" -DestinationPath "D:\Restored\Projects" -CreateMissingFiles

#>
param(
    [Parameter(Mandatory, Position=0)]
    [string]$InputPath,

    [Parameter(Mandatory, Position=1)]
    [string]$DestinationPath,

    [switch]$CreateMissingFiles
)

# Resolve and normalize destination path
if (-not (Test-Path -LiteralPath $DestinationPath)) {
    try {
        New-Item -ItemType Directory -LiteralPath $DestinationPath -Force | Out-Null
    } catch {
        Write-Error "Failed to create destination path $DestinationPath. $_"
        return
    }
}
$destItem = Get-Item -LiteralPath $DestinationPath
$destPath = $destItem.FullName
if ($destPath.Length -gt 1 -and $destPath.EndsWith('\')) {
    if (!($destPath -match '^[A-Za-z]:\\$' -or $destPath -match '^\\\\[^\\]+\\[^\\]+\\?$')) {
        $destPath = $destPath.TrimEnd('\')
    }
}

Write-Host "Importing ACLs to destination: $destPath" -ForegroundColor Cyan

# Load ACL entries from the input file (handle GZip if needed)
try {
    if ($InputPath.EndsWith('.gz')) {
        # Compressed input: decompress and deserialize
        Write-Verbose "Decompressing GZip file $InputPath"
        $fs = [System.IO.File]::OpenRead($InputPath)
        $gzipStream = New-Object System.IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Decompress)
        $streamReader = New-Object System.IO.StreamReader($gzipStream)
        $xmlContent = $streamReader.ReadToEnd()
        $streamReader.Close(); $gzipStream.Close(); $fs.Close()
        $aclEntries = [System.Management.Automation.PSSerializer]::Deserialize($xmlContent)
    } else {
        $aclEntries = Import-Clixml -LiteralPath $InputPath
    }
} catch {
    Write-Error "Failed to read or parse InputPath file $InputPath. $_"
    return
}

# Ensure we have a collection of entries
if ($aclEntries -is [System.Array]) {
    $entriesList = $aclEntries
} else {
    $entriesList = @($aclEntries)
}

# Sort entries so that directories are created before files inside them.
# Sorting by path depth (number of path segments in RelativePath).
$entriesList = $entriesList | Sort-Object { ($_.RelativePath -split '\\').Length }

# Total count for progress display
$total = $entriesList.Count
$counter = 0

foreach ($entry in $entriesList) {
    $counter++
    $percent = [math]::Floor(($counter / $total) * 100)
    Write-Progress -Activity "Importing ACLs" -Status "Processing $counter of $total items (`"$percent%`")" -PercentComplete $percent

    # Determine target full path for this entry
    $relativePath = $entry.RelativePath
    if ($relativePath -eq '.' -or [string]::IsNullOrEmpty($relativePath)) {
        $targetPath = $destPath
    } else {
        $targetPath = Join-Path -LiteralPath $destPath -ChildPath $relativePath
    }

    $isDir = $entry.IsDirectory -eq $true
    $sdBytes = $entry.SDBytes

    if ($isDir) {
        # Ensure directory exists
        if (-not (Test-Path -LiteralPath $targetPath)) {
            try {
                New-Item -ItemType Directory -LiteralPath $targetPath -Force | Out-Null
            } catch {
                Write-Error "Could not create directory $targetPath: $($_.Exception.Message)"
                continue
            }
        }
        # Apply directory ACL
        try {
            $dirSec = New-Object System.Security.AccessControl.DirectorySecurity
            $dirSec.SetSecurityDescriptorBinaryForm($sdBytes)
            [System.IO.Directory]::SetAccessControl($targetPath, $dirSec)
        } catch {
            # If setting owner failed due to lack of privilege, try without changing owner
            if ($_.Exception.Message -match 'not allowed to be the owner' -or $_.Exception.Message -match 'unauthorized') {
                Write-Warning "Insufficient privilege to set original owner on $targetPath. Retaining current owner and applying other ACL parts."
                try {
                    $currentSec = [System.IO.Directory]::GetAccessControl($targetPath)
                    $currentOwner = $currentSec.GetOwner([System.Security.Principal.NTAccount])
                    $dirSec.SetOwner($currentOwner)  # override owner to current
                    [System.IO.Directory]::SetAccessControl($targetPath, $dirSec)
                } catch {
                    Write-Error "Failed to apply ACL to directory $targetPath even after keeping current owner. $($_.Exception.Message)"
                }
            } else {
                Write-Error "Failed to apply ACL to directory $targetPath. $($_.Exception.Message)"
            }
        }
    }
    else {
        # File entry
        if (-not (Test-Path -LiteralPath $targetPath)) {
            if ($CreateMissingFiles) {
                # Create an empty file (and any necessary directories in path)
                try {
                    $null = New-Item -ItemType File -LiteralPath $targetPath -Force
                } catch {
                    Write-Error "Could not create missing file $targetPath: $($_.Exception.Message)"
                    continue
                }
            } else {
                Write-Warning "File not found: $targetPath. Skipping ACL for this missing file (use -CreateMissingFiles to create it)."
                continue
            }
        }
        # Apply file ACL
        try {
            $fileSec = New-Object System.Security.AccessControl.FileSecurity
            $fileSec.SetSecurityDescriptorBinaryForm($sdBytes)
            [System.IO.File]::SetAccessControl($targetPath, $fileSec)
        } catch {
            if ($_.Exception.Message -match 'not allowed to be the owner' -or $_.Exception.Message -match 'unauthorized') {
                Write-Warning "Insufficient privilege to set original owner on $targetPath. Retaining current owner and applying other ACL parts."
                try {
                    $currentSec = [System.IO.File]::GetAccessControl($targetPath)
                    $currentOwner = $currentSec.GetOwner([System.Security.Principal.NTAccount])
                    $fileSec.SetOwner($currentOwner)
                    [System.IO.File]::SetAccessControl($targetPath, $fileSec)
                } catch {
                    Write-Error "Failed to apply ACL to file $targetPath even after keeping current owner. $($_.Exception.Message)"
                }
            } else {
                Write-Error "Failed to apply ACL to file $targetPath. $($_.Exception.Message)"
            }
        }
    }
}

Write-Progress -Activity "Importing ACLs" -Completed
Write-Host "Import completed. Processed $counter items. ACLs have been applied under $destPath." -ForegroundColor Green

How it works: The import script takes the backup file and target base path as input. It first loads the backup data with Import-Clixml (and if the file is GZip-compressed, it transparently decompresses it before deserialization). The entries are sorted so that parent directories are created before their children. For each entry, the script constructs the full path under the destination and ensures the item exists (creating directories always, and files if -CreateMissingFiles is specified). Then it reconstructs the security descriptor:
	•	For directories, it uses a DirectorySecurity object and calls SetSecurityDescriptorBinaryForm(byte[]) to import the saved ACL bytes, then applies it with [System.IO.Directory]::SetAccessControl() on the target path.
	•	For files, it similarly uses a FileSecurity object and [System.IO.File]::SetAccessControl(). This separation ensures we use the correct ACL type for each item.

When applying ACLs, if an “unauthorized” error occurs due to owner setting (which can happen if the script is not running with SeRestorePrivilege elevated rights ￼), the script catches it. In that case, it logs a warning and resets the security descriptor’s owner to the current owner of the target item (so it doesn’t attempt to change ownership) and retries. This way, at least the DACL and SACL are applied, and the script avoids failing outright ￼. (By default, Windows only allows setting an object’s owner to yourself or Administrators group, unless running with special privileges ￼.)

The script uses Join-Path -LiteralPath to combine the base path and relative paths safely, and handles the case where the relative path is just “.” (representing the root itself). Progress is shown via Write-Progress so you can monitor large restores. Missing files are created as zero-byte files if -CreateMissingFiles is used, otherwise those ACL entries are skipped with a warning.

Usage Notes: Run these scripts in an elevated PowerShell session (as Administrator) to ensure access to all ACL information, especially if SACL (audit) data needs to be captured ￼ and to allow restoring owners properly. For very long paths, the use of -LiteralPath and .NET methods supports extended-length UNC syntax (e.g. \\?\ paths) if needed ￼. The output CLIXML can be large; using the -Compress option on export will produce a .gz file, which the import script can read directly. These rewritten scripts provide a robust solution for backing up and restoring NTFS permissions in enterprise scenarios, with clear logging and error handling throughout.

Sources:
	•	Microsoft Docs – Get-Acl (using -Audit to include SACL audit entries) ￼.
	•	Microsoft Docs – ObjectSecurity.GetSecurityDescriptorBinaryForm (obtaining raw security descriptor bytes) ￼.
	•	Microsoft Docs – Many cmdlets support -LiteralPath to treat paths literally (avoid wildcard issues) ￼.
	•	ServerFault – NTFS ownership can only be set to certain principals without special privileges ￼.
	•	Super User – Changing owner via Set-Acl requires SeRestorePrivilege (i.e. elevation) ￼, hence our owner-setting workaround.
	•	Blue42 Blog – Notes on PowerShell 5 vs 6 ACL APIs (PowerShell 7 reintroduces full ACL support) ￼.