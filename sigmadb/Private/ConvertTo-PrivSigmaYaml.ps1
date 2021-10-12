<#
.SYNOPSIS
    sigmadb - convert sigma rule from database to yaml (private function)
.DESCRIPTION
    Private function for converting sigma rule from sigmadb to yaml with the custom exceptions
.EXAMPLE
    PS C:\> ConvertTo-PrivSigmaYaml -Rule $rule -Database $db
    Converts the selected rule from the defined database to a yaml file
.INPUTS
    Rule: DataRow from SQL query
    Database: SigmaDB class object
.OUTPUTS
    YAML file
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
    1.0.1   16.09.2021  ncrqnt      Removed support for multiple documents
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

#Requires -Module 'SimplySql'
#Requires -Module 'powershell-yaml'

function ConvertTo-PrivSigmaYaml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.DataRow]$Rule,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
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
        # Get exceptions
        $exceptions = $db.Query("SELECT * FROM exception WHERE rule_id = @id", @{ id = $Rule.id })

        # Get file data
        $yaml = Get-Content "$($Config.Folders.Rules)\$($Rule.file_name)" -Raw -Encoding utf8
        $dict = $yaml | ConvertFrom-Yaml -Ordered

        # Add exceptions to yaml
        if ($exceptions.Count -gt 0) {
            $yaml = (Add-PrivSigmaException -RuleDict $dict -ExceptionList $exceptions) | ConvertTo-Yaml
        }

        return $yaml
    }

    end {
        # nothing to do
    }
}