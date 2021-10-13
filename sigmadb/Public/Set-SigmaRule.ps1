<#
.SYNOPSIS
    sigmadb - change rule in database
.DESCRIPTION
    Set/Change existing rule in database.
.INPUTS
    Id: Rule id
    Config: Path to config file. default: .\sigmadb\config.yml
    FileName: New rule file name
    FileHash: File hash of current rule file
    IsEql: Rule has to be converted to EQL ('near' aggregation)
    IsCustom: Rule is self-written
    IsEnabled: Rule is enabled (see Enable-SigmaRule / Disable-SigmaRule)
    IgnoreHash: File hash to be ignored for updates
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       22.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.0   22.09.2021  ncrqnt      Initial creation
#>

function Set-SigmaRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$Id,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.yml',
        [Parameter(Mandatory = $false)]
        [string]$FileName,
        [Parameter(Mandatory = $false)]
        [string]$FileHash,
        [Parameter(Mandatory = $false)]
        [bool]$IsEql,
        [Parameter(Mandatory = $false)]
        [bool]$IsCustom,
        [Parameter(Mandatory = $false)]
        [bool]$IsEnabled,
        [Parameter(Mandatory = $false)]
        [string]$IngoreHash
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        $params = $PSBoundParameters
        $params.Remove('Id') | Out-Null
        $params.Remove('Config') | Out-Null
        if ($params.Count -eq 0) {
            Write-Warning -Message "No parameters passed. Nothing to do."
            return
        }
        else {
            $rule = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $Id })[0]

            if ($null -ne $rule) {
                if (-not $params.ContainsKey('FileName')) {
                    $FileName = $rule.file_name
                }

                if (-not $params.ContainsKey('FileHash')) {
                    $FileHash = $rule.file_hash
                }

                if (-not $params.ContainsKey('IsEql')) {
                    $IsEql = $rule.is_eql
                }

                if (-not $params.ContainsKey('IsCustom')) {
                    $IsCustom = $rule.is_custom
                }

                if (-not $params.ContainsKey('IsEnabled')) {
                    $IsEnabled = $rule.is_enabled
                }

                if (-not $params.ContainsKey('IngoreHash')) {
                    $IngoreHash = $rule.ignore_hash
                }

                $parameters = @{
                    id         = $Id
                    fileName   = $FileName
                    fileHash   = $FileHash
                    isEql      = [int]$IsEql
                    isCustom   = [int]$IsCustom
                    isEnabled  = [int]$IsEnabled
                    ignoreHash = $IngoreHash
                    updateDate = Get-Date -Format 'o'
                }

                if ($PSCmdlet.ShouldProcess($rule.title, "Set-SigmaRule")) {
                    $query = "UPDATE rule
                              SET    file_name   = @fileName,
                                     file_hash   = @fileHash,
                                     is_eql      = @isEql,
                                     is_custom   = @isCustom,
                                     is_enabled  = @isEnabled,
                                     ignore_hash = @ignoreHash,
                                     update_date = @updateDate
                              WHERE id = @id"
                    $db.Update($query, $parameters)
                    Write-Output "Rule '$Id' successfuly updated"
                    return
                }
            }
            else {
                Write-Warning "No rule with id '$Id' found."
            }
        }
    }

    end {
        $db.Close()
    }
}