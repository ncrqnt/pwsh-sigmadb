<#
.SYNOPSIS
    sigmadb - show sigma rule from db (private)
.DESCRIPTION
    Private function for Get-SigmaRule
.EXAMPLE
    PS C:\> Get-PrivSigmaRule -Id $ruleid -Database $db
    Returns sigma rule and its exceptions from database.
.INPUTS
    Id: rule id
    Database: SigmaDB class object
    Type: Output type. Default: 'Plain' (OrderedDictionary)
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    2.1.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
    2.0.0   09.09.2021  ncrqnt      Reworked function:
                                    + Added parameter for output type (either YAML, JSON or OrderedDictionary)
                                    * Changed: Using ConvertTo-PrivSigmaYaml instead of custom query/build
    1.0.1   07.09.2021  ncrqnt      Fixed description
                                    Added error-handling when rule id not found
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

#Requires -Module 'SimplySql'
#Requires -Module 'powershell-yaml'

function Get-PrivSigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database,
        [Parameter(Mandatory = $false)]
        [string]$Type
    )

    begin {
        $db = $Database

        # check for db connection
        if (-not $db.Test()) {
            Write-Error -Message "No database connection found"
            return
        }
    }

    process {
        try {
            $rule = $db.Query("SELECT * FROM rule WHERE id = @id",@{ id = $Id })[0]

            if ($null -ne $rule) {
                $yaml = ConvertTo-PrivSigmaYaml -Rule $rule -Config $Config -Database $db
                $dict = $yaml | ConvertFrom-Yaml -AllDocuments -Ordered

                if ($Type -eq 'JSON') {
                    return ($dict | ConvertTo-Json -Depth 10)
                }
                elseif ($Type -eq 'YAML') {
                    return $yaml
                }
                elseif ($Type -eq 'Plain') {
                    return $dict
                }
            }
            else{
                Write-Warning -Message "No rule with id '$Id' found"
            }
        }
        catch {
            Write-Error -Message "Could not read rule '$Id': $_"
            return
        }
    }

    end {
        # nothing to do
    }
}