<#
.SYNOPSIS
    sigmadb - Eanbles sigma rule
.DESCRIPTION
    Enables sigma rule, so it'öö be updated and exported automatically again
.NOTES
    Author:     ncrqnt
    Date:       15.09.2021
    PowerShell: 7.1.4

    Changelog:
    2.0.0   22.09.2021  ncrqnt      Reworked: Use Set-SigmaRule
    1.0.2   22.09.2021  ncrqnt      Changed call of SigmaDB class
    1.0.1   16.09.2021  ncrqnt      Restructure of config file
    1.0.0   15.09.2021  ncrqnt      Initial creation
#>

function Enable-SigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$Id,
        [Parameter(Mandatory = $false)]
        [string]$Config = ".\sigmadb\config.json"
    )

    process {
        Set-SigmaRule -Id $Id -Config $Config -IsEnabled $true
    }
}