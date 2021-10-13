<#
.SYNOPSIS
    sigmadb New Sigma Config (private function)
.DESCRIPTION
    Creates new sigma config
.NOTES
    Author:     ncrqnt
    Date:       13.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.0   22.09.2021  ncrqnt      Changed default path to a relative path
    1.0.3   14.09.2021  ncrqnt      Fixed what if preference
    1.0.2   14.09.2021  ncrqnt      Added error handling
    1.0.1   14.09.2021  ncrqnt      Added Should Process
    1.0.0   13.09.2021  ncrqnt      Initial creation
#>

function New-PrivSigmaConfig {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Config
    )
    try {
        New-Item -Path $Config -ItemType File -Force -WhatIf:$WhatIfPreference -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Could not create config file: $_"
        return
    }
    $root = Split-Path (Resolve-Path -Path $Config -Relative)

    $settings = @"
# File locations
Files:
  Database: '$root\database.db'

# Folder locations
Folders:
  Root: '$root'
  Rules: '$root\rules'
  Exports: '$root\exports'

# Rule specific settings
RuleSettings:
  CustomTags:             # Rules with custom tags are ignored during update process
    - custom

# Export settings for elasticsearch
ExportToElastic:
  Enabled: false
  URL: <hostname:port>    # elasticsearch url and port

# Case-sensitivity settings
CaseSensitivity:
  Enabled: false
  Mode: lowercase         # currently supported: 'lowercase', 'uppercase' / default: 'lower'
  AllFields: false        # if true all fields are transformed, else only the listed under 'Fields'
  Fields:
    - process.name
    - host.name
    - user.name
"@

    $settings | Out-File -FilePath $Config -Encoding utf8
    $cfg = Get-Content $Config -Raw -Encoding utf8 | ConvertFrom-Yaml -Ordered

    # Create file structure
    try {
        New-Item -Path $cfg.Folders.Rules -ItemType Directory -WhatIf:$WhatIfPreference -ErrorAction Stop | Out-Null
        New-Item -Path $cfg.Folders.Exports -ItemType Directory -WhatIf:$WhatIfPreference -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Could not create file structure from config: $_"
        return
    }

    return $cfg
}