<#
.SYNOPSIS
    sigmadb - Set Sigma Exception
.DESCRIPTION
    Changes existing exception for a sigma rule in the database
.EXAMPLE
    PS C:\> Set-SigmaException -Id '1' -Operator 'nand' -SearchId 'filter' -Filter '{"LogonType":9,"user.name":"user1"}' -Database .\test.db
    Changes existing exception for sigma rule '1' in Database .\test.db with the following YAML structure:
        filter:
            LogonType: 9
            user.name: 'user1'
        [...]
        condition: [...] and not filter
.INPUTS
    Id: Sigma rule ID
    Operator: Condition operator (and, nand, or,  nor)
    SearchId: Desired search identifier for the sigma rule
    Filter: The content filter
    Database: Path to database file
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.2   22.09.2021  ncrqnt      Changed call of SigmaDB class
    1.1.1   16.09.2021  ncrqnt      Restructure of config file
    1.1.0   13.09.2021  ncrqnt      Changed Database parameter to Config
    1.0.2   08.09.2021  ncrqnt      Added replacement for not-operators
    1.0.1   08.09.2021  ncrqnt      Changed parameter order and made them all mandatory
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

function Set-SigmaException {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$SearchId,
        [Parameter(Mandatory = $true)]
        [ValidateSet('and', 'nand', 'or', 'nor')]
        [string]$Operator,
        [Parameter(Mandatory = $true)]
        [ValidateScript({if (Test-Json $_) { $true } else { throw "'$_' is not a valid JSON format!"}})]
        [string]$Filter,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.yml'
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        # replace 'not' operator abbrevation
        switch ($Operator) {
            'nand' { $Operator = 'and not' }
            'nor' { $Operator = 'or not'}
        }

        # check if rule exist
        $rule = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $Id })

        if ($rule.Count -gt 0) {
            $exceptions = $db.Query("SELECT * FROM exception WHERE rule_id = @id", @{ id = $Id })

            if ($exceptions.Count -gt 0) {
                if ($SearchId -in $exceptions.search_identifier) {
                    $exception = $exceptions | Where-Object { $_.search_identifier -eq $SearchId }
                    if ($PSCmdlet.ShouldProcess($cfg.Files.Database, "Set-PrivSigmaException")) {
                        Set-PrivSigmaException -ExceptionId $exception.id -RuleId $Id -Operator $Operator -SearchId $SearchId -Filter $filter -Database $db
                    }
                }
                else {
                    Write-Warning "Search Identifier '$SearchId' not found for rule '$Id'. Use New-SigmaException instead."
                }

            }
            else {
                Write-Warning "No exceptions found for rule '$Id'. Use New-SigmaException instead."
            }
        }
        else {
            Write-Warning -Message "No rule with id '$Id' found."
        }
    }

    end {
        $db.Close()
    }
}