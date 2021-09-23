<#
.SYNOPSIS
    sigmadb - Set Sigma Exception (private function)
.DESCRIPTION
    Changes existing exception for a sigma rule in the database
.EXAMPLE
    PS C:\> Set-PrivSigmaException -ExceptionId 1 -RuleId 2 -Operator 'nand' -SearchId 'filter' -Filter '{"LogonType":9,"user.name":"user1"} -Database $db'
    Changes exception 1 for sigma rule 2 in Database $db with the following YAML structure:
        filter:
            LogonType: 9
            user.name: 'user1'
        [...]
        condition: [...] and not filter
.INPUTS
    ExceptionId: exception ID
    RuleId: Sigma rule ID
    Operator: condition operator (and, nand, or,  nor)
    SearchId: Desired search identifier for the sigma rule
    Filter: The content filter
    Database: SigmaDB class object
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.1   10.09.2021  ncrqnt      Removed parameter validation
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

function Set-PrivSigmaException {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RuleId,
        [Parameter(Mandatory = $true)]
        [string]$ExceptionId,
        [Parameter(Mandatory = $false)]
        [string]$Operator,
        [Parameter(Mandatory = $false)]
        [string]$SearchId,
        [Parameter(Mandatory = $true)]
        [string]$Filter,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database
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
        $parameters = @{
            id       = $ExceptionId
            operator = $Operator
            searchid = $SearchId
            filter   = $Filter
            ruleid   = $RuleId
        }

        $update = " UPDATE exception
                    SET operator = @operator,
                        search_identifier = @searchid,
                        filter = @filter,
                        rule_id = @ruleid
                    WHERE id = @id"

        if ($PSCmdlet.ShouldProcess($db.database, $insert)) {
            $db.Update($update, $parameters)
        }
    }

    end {
        # nothing to do
    }
}