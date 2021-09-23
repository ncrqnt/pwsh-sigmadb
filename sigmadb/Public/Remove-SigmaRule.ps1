<#
.SYNOPSIS
    sigmadb - delete sigma rule from db
.DESCRIPTION
    Removes a sigma rule from the database
.EXAMPLE
    PS C:\> Remove-SigmaRule -Id '1' -Database .\sigma.db
    Removes Sigma rule 1 with its exceptions from the database
.INPUTS
    Id: rule id
    Database: path to sql database
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.2.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
                                    Changed call of SigmaDB class
    1.1.1   16.09.2021  ncrqnt      Restructure of config file
    1.1.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

function Remove-SigmaRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Rule')]
        [string]$Id,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.json'
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        $select = "SELECT * FROM rule WHERE id = @id"
        $rule = $db.Query($select, @{ id = $Id })[0]

        if ($null -ne $rule) {
            if ($PSCmdlet.ShouldProcess($cfg.Files.Database, "DELETE FROM rule WHERE id = '$Id'")) {
                Remove-Item "$($cfg.Folders.Rules)\$($rule.file_name)" | Out-Null
                $db.Update("DELETE FROM rule WHERE id = @id", @{ id = $Id })
                Write-Output "Rule '$Id' successful deleted"
                return
            }
        }
        else {
            Write-Warning -Message "No rule with id '$Id' found"
            return
        }
    }

    end {
        $db.Close()
    }
}