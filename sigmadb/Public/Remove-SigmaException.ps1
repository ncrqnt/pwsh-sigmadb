<#
.SYNOPSIS
    sigmadb - delete exception from sigma rule
.DESCRIPTION
    Removes an exception for a sigma rule in the selected database
.EXAMPLE
    PS C:\> Remove-SigmaException -Id 1 -SearchId 'filter' -Database .\sigma.db
    Removes filter with search identifier 'filter' from rule 1
.INPUTS
    Id: Rule id
    SearchId: Search identifier
    Database: Path to sql database
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.2.0   22.09.2021  ncrqnt      Changed call of SigmaDB class
    1.1.1   16.09.2021  ncrqnt      Restructure of config file
    1.1.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

function Remove-SigmaException {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('RuleId')]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$SearchId,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.json'
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        $rule = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $Id })


        if ($rule.Count -gt 0) {
            $exceptions = $db.Query("SELECT * FROM exception WHERE rule_id = @id", @{ id = $Id })

            if ($exceptions.Count -gt 0) {
                if ($SearchId -in $exceptions.search_identifier) {
                    $exception = $exceptions | Where-Object { $_.search_identifier -eq $SearchId }
                    $delete = "DELETE FROM exception WHERE id = @id"

                    if ($PSCmdlet.ShouldProcess($cfg.Files.Database, "DELETE FROM exception WHERE id = '$($exception.id)'")) {
                        $db.Update($delete, @{ id = $exception.id })
                        Write-Output "Exception '$($exception.id)' from rule '$Id' successfully deleted"
                    }
                }
                else {
                    Write-Warning "No Search identifier '$SearchId' found for rule '$Id'."
                }
            }
        }
        else {
            Write-Warning -Message "No rule with id '$Id' found"
        }
    }

    end {
        $db.Close()
    }
}