<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Author:     ncrqnt
    Date:       13.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.1   22.09.2021  ncrqnt      Made $Config mandatory
    1.0.0   13.09.2021  ncrqnt      Initial creation
#>

function Get-PrivSigmaConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Config
    )

    if (Test-Path $Config) {
        $cfg = Get-Content -Path $Config | ConvertFrom-Yaml -Ordered

        $testpaths = @($cfg.Folders.Root, $cfg.Folders.Rules, $cfg.Folders.Exports)

        foreach ($path in $testpaths) {
            if (-not (Test-Path $path)) {
                Write-Verbose "'$path' not found. Creating directory."
                New-Item -Path $path -ItemType Directory -Force | Out-Null
            }
        }
    }
    else {
        $cfg = New-PrivSigmaConfig -Config $Config
    }

    return $cfg
}