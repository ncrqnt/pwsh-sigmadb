<#
.SYNOPSIS
    sigmadb - Update sigma rules in sigmadb
.DESCRIPTION
    Compare and Update sigma rules inside the database
.EXAMPLE
    PS C:\> Update-SigmaRule -RulesFolder .\sigma\rules -Config .\sigmadb\config.yml
    Checks for each yml/yaml file in .\sigma\rules if it's in the database and compares hash.
    If the hash mismatch, the content will be comapred and the user has to choose to update or not
.INPUTS
    RulesFolder: folder with the new sigma rules (usually inside sigma\rules)
    Config: config file for sigmadb
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       10.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.4.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
                                    Changed call of SigmaDB class
    1.3.1   16.09.2021  ncrqnt      Restructure of config file
    1.3.0   15.09.2021  ncrqnt      Added support for updating disabled rules
    1.2.0   14.09.2021  ncrqnt      Added better file comparision
                                    Changed 'Yes' process of Should process
    1.1.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.0.0   10.09.2021  ncrqnt      Initial creation
#>

function Update-SigmaRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (Test-Path $_ -PathType Container) { $true } else { throw "$_ is not a directory." } })]
        [string]$RulesFolder,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.yml',
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDisabled
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        $rulesPath = (Get-Item $RulesFolder).FullName
        $rules = Get-ChildItem -Path "$rulesPath\*" -Include *.yml, *.yaml -Recurse -File

        foreach ($rule in $rules) {
            $yaml = Get-Content -Path $rule.FullName -Encoding utf8 -Raw | ConvertFrom-Yaml -Ordered
            $rule_db = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $yaml.id })[0]

            if ($null -ne $rule_db) {
                $rule_hash = (Get-FileHash $rule.FullName -Algorithm SHA256).Hash
                if ($rule_db.is_enabled -eq 0 -and -not $IncludeDisabled) {
                    Write-Verbose -Message "Rule '$($rule_db.title)' is disabled. Use -IncludeDisabled to check updates for it."
                }
                elseif ($rule_hash -ne $rule_db.file_hash -and $rule_hash -ne $rule_db.ignore_hash) {

                    Write-Output "==============================================================="
                    Compare-FileContent -ReferenceObject "$($cfg.Folders.Rules)\$($rule_db.file_name)" -DifferenceObject $rule
                    Write-Output "===============================================================`n"

                    $date = Get-Date -Format 'o'
                    if ($PSCmdlet.ShouldProcess($rule_db.title, "Update Rule")) {
                        Copy-Item -Path $rule -Destination $cfg.Folders.Rules -Force | Out-Null
                        $file = Get-Item "$($cfg.Folders.Rules)\$($rule.Name)"
                        Import-PrivSigmaRule -File $file -Rule $yaml -Database $db -Config $Config -Force -InformationAction Continue
                    }
                    else {
                        $query = "UPDATE rule SET ignore_hash = @hash, update_date = @date WHERE id = @id"
                        $db.Update($query, @{ hash = $rule_hash; date = $date; id = $rule_db.id })
                    }
                }
                else {
                    Write-Verbose -Message "Rule '$($rule_db.title)' is identical"
                }
            }
            else {
                Write-Output "New rule $($yaml.title)"
                $rule.FullName | Out-File "$($cfg.Folders.Root)\new_rules.txt" -Append -Encoding utf8
            }
        }
    }

    end {
        $db.Close()
    }
}