<#
.SYNOPSIS
    sigmadb - export rule from database (private function)
.DESCRIPTION
    Private function for Export-SigmaRule
.EXAMPLE
    PS C:\> Export-PrivSigmaRule -Rule $rule -Destination .\export\ -Database $db -Elastic -SigmaRepo .\sigma
    Exports the selected rule to the destination folder from database and directly converts it to elastic
.INPUTS
    Rule: Ordered dictionary with sigma rule
    Destination: path to export directory
    Database: SigmaDB class object
    Elastic: Switch to not only output sigma rule file (.yml) but also elastic ndjson file
    SigmaRepo: Path to sigma repo (needed when Type is elastic)
    BackendConfig: Path to sigmac (elasticsearch) backend config
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.1   22.09.2021  ncrqnt      Fixed disabled rule not being disabled in elastic
    1.1.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
    1.0.1   16.09.2021  ncrqnt      Removed support for multiple documents
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

#Requires -Module 'SimplySql'
#Requires -Module 'powershell-yaml'

function Export-PrivSigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.DataRow]$Rule,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database,
        [Parameter(Mandatory = $true)]
        [string]$SigmaRepo,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory = $false)]
        [switch]$Elastic,
        [Parameter(Mandatory = $false)]
        [string]$BackendConfig
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
        # convert to yaml and export to destination
        $filename = $Rule.file_name
        $exportpath = "$Destination\$filename"
        ConvertTo-PrivSigmaYaml -Rule $Rule -Config $Config -Database $db | Out-File -FilePath $exportpath -Encoding utf8
        $filepath = (Resolve-Path $exportpath).Path

        if ($Elastic) {
            if ($Rule.is_eql -eq 0) {
                $arg_target = '-t', 'es-rule'
            }
            else {
                $arg_target = '-t', 'es-rule-eql'
            }

            if ($BackendConfig) {
                $file = Get-Item $BackendConfig
                $arg_backendconfig = "-C", "$($file.FullName)"
            }

            $currentloc = (Get-Location).Path
            Set-Location $SigmaRepo

            $ndjson = pipenv.exe run python.exe .\tools\sigmac -c winlogbeat-modules-enabled -oF json $arg_target $arg_backendconfig $filepath
            $dict = $ndjson | ConvertFrom-Json
            $rule_db = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $dict.rule_id })

            if ($rule_db.is_enabled -eq 0) {
                $dict.enabled = $false
            }

            $ndjson = $dict | ConvertTo-Json -Compress -Depth 10

            Set-Location $currentloc

            $ndjson | Out-File -FilePath "$Destination\rule_import.ndjson" -Encoding utf8 -Append
        }
    }

    end {
        # nothing to do
    }
}