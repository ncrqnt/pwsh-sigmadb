<#
.SYNOPSIS
    sigmadb - get sigma rule from db
.DESCRIPTION
    Show sigma rule and its exceptions from sigma database
.EXAMPLE
    PS C:\> Get-SigmaRule -Id '1' -Database .\sigma.db
    Returns Sigma rule 1 with its exceptions if it haves any
.EXAMPLE
    PS C:\> Get-SigmaRule -Database .\sigma.db
    List all rules in database with their exceptions (if there are any)
.INPUTS
    Id: optional rule id
    Database: path to sql database
    Type: Output type ('JSON', 'YAML' or 'Plain'). Default: 'Plain'
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.3.1   27.09.2021  ncrqnt      Fixed missing Config parameter
    1.3.0   22.09.2021  ncrqnt      Added usage of config file to private function
                                    Changed call of SigmaDB class
    1.2.1   16.09.2021  ncrqnt      Restructure of config file
    1.2.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.1.0   09.09.2021  ncrqnt      Added 'Type' parameter
    1.0.1   07.09.2021  ncrqnt      Fixed description
                                    Added error-handling when no rule found
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

function Get-SigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Alias('Name', 'Rule')]
        [string]$Id,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.json',
        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'YAML', 'Plain')]
        [string]$Type = 'Plain'
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        if ($Id) {
            # show only single rule
            Get-PrivSigmaRule -Id $Id -Config $cfg -Database $db -Type $Type
        }
        else {
            # show all rule
            $ids = $db.Query("SELECT id FROM rule").id

            if ($ids.count -gt 0) {
                foreach ($id in $ids) {
                    Get-PrivSigmaRule -Id $id -Config $cfg -Database $db -Type $Type
                }
            }
            else {
                Write-Warning "No rules found in database"
            }
        }
    }

    end {
        $db.Close()
    }
}