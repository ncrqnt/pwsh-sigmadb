<#
.SYNOPSIS
    sigmadb - Export sigma rule from db
.DESCRIPTION
    Exports single (or all) sigma rules either to a YAML file or directly to Elastic ndjson (sigma repo required)
.EXAMPLE
    PS C:\> Export-SigmaRule -Id 1 -Destination .\export\ -Database .\test.db -SigmaRepo .\sigma
    Exports Rule 1 (with exceptions) to .\export\[filename] from .\test.db database as sigma rule file (.yml)
    Sigma Repo is needed for converting rules with multiple yaml documents
.INPUTS
    Id: Optional sigma rule id
    Destination: Destination folder for export
    Database: Path to database file
    SigmaRepo: Path to sigma repo
    Elastic: Switch for converting directly to elastic rule (needs sigmac)
    BackendConfig: Path to sigmac (elasticsearch) backend config file
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.3.0   22.09.2021  ncrqnt      Added usage of config file in private function
                                    Changed call of SigmaDB class
    1.2.1   16.09.2021  ncrqnt      Restructure of config file
    1.2.0   15.09.2021  ncrqnt      Added support for exporting disabled rules
    1.1.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

function Export-SigmaRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'medium')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName='sigma')]
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [string]$Id,
        [Parameter(Mandatory = $false, ParameterSetName='sigma')]
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [string]$Destination,
        [Parameter(Mandatory = $false, ParameterSetName='sigma')]
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [string]$Config = '.\sigmadb\config.yml',
        [Parameter(Mandatory = $false, ParameterSetName='sigma')]
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [switch]$NoProgressBar,
        [Parameter(Mandatory = $false, ParameterSetName='sigma')]
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [switch]$ExcludeDisabled,

        [Parameter(Mandatory = $true, ParameterSetName='elastic')]
        [switch]$Elastic,
        [Parameter(Mandatory = $true, ParameterSetName='elastic')]
        [ValidateScript( { if (Test-Path $_ -PathType Container) { $true } else { throw "$_ is not a directory." } })]
        [string]$SigmaRepo,
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [ValidateScript( { if (Test-Path $_ -PathType Leaf) { $true } else { throw "$_ not found or not a file." } })]
        [string]$BackendConfig,
        [Parameter(Mandatory = $false, ParameterSetName='elastic')]
        [pscredential]$Credential
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database

        if (-not $Destination) {
            $Destination = $cfg.Folders.Exports
        }

        if (-not $Credential) {
            if ($cfg.ExportToElastic.Enabled -and $Elastic) {
                Write-Warning "Export to Elastic was enabled in the config.yml"
                $Credential = Get-Credential -Message "Please enter credential for $($cfg.ExportToElastic.URL)" -Title "Elastic Credential Request"
            }
        }

        if (-not (Test-Path $Destination -PathType Container)) {
            Write-Error "Destination '$Destination' does not exist or is not a folder" -ErrorAction Stop
            return
        }
        else {
            Get-ChildItem $Destination -Recurse | ForEach-Object { Remove-Item $_ | Out-Null }
        }
    }

    process {
        if ($Id) {
            # single rule
            $rule = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $Id })[0]

            if ($rule.is_enabled -eq 0 -and $ExcludeDisabled) {
                Write-Verbose "Rule '$Id' is disabled and -ExcludeDisabled was passed. Skipping rule."
            }
            elseif ($rule.Count -gt 0) {
                Export-PrivSigmaRule -Rule $rule -Destination $Destination -Database $db -Config $cfg -SigmaRepo:$SigmaRepo -Elastic:$Elastic -BackendConfig:$BackendConfig
                Write-Output "Rule exported: '$($rule.title)'"
            }
            else {
                Write-Warning "No rule with id '$Id' found."
            }
        }
        else {
            $rules = $db.Query("SELECT * FROM rule")

            if ($rules.Count -gt 0) {
                $i = 1
                foreach ($rule in $rules) {
                    if ($rule.is_enabled -eq 0 -and $ExcludeDisabled) {
                        Write-Verbose "Rule '$Id' is disabled and -ExcludeDisabled was passed. Skipping rule."
                    }
                    else {
                        $max = $rules.Count
                        $num = "{0:d$(([string]$max).Length)}" -f $i
                        $percent = 100 / $max * $i
                        $name = $rule.title

                        if (-not $NoProgressBar) {
                            Write-Progress -Activity "Exporting" -Status "$num / $max completed" -PercentComplete $percent -CurrentOperation "Rule: $name"
                        }
                        else {
                            Write-Output "[$num/$max] $name"
                        }
                        Export-PrivSigmaRule -Rule $rule -Destination $Destination -Database $db -SigmaRepo $SigmaRepo -Config $cfg -Elastic:$Elastic -BackendConfig:$BackendConfig
                        $i++
                    }
                }
            }
            else {
                Write-Warning "No rules in database '$($cfg.Files.Database)' found."
            }
        }

        if ($cfg.ExportToElastic.Enabled -and $Elastic) {
            $importFile = "$Destination\rule_import.ndjson"
            $parameters = @{
                Method         = 'Post'
                Uri            = "$($cfg.ExportToElastic.URL)/api/detection_engine/rules/_import?overwrite=true"
                Headers        = @{'kbn-xsrf' = 'randombullshitgo' }
                ContentType    = 'multipart/form-data'
                Form           = @{file = Get-Item $importFile }
                Credential     = $Credential
                Authentication = 'Basic'
            }

            if ($PSCmdlet.ShouldProcess("'$importFile' ($((Get-Content $importFile -Encoding utf8).Length) rules)", "Upload to Elastic ($($cfg.ExportToElastic.URL))")) {
                Invoke-RestMethod @parameters
            }
        }
    }

    end {
        $db.Close()
    }
}