<#
.SYNOPSIS
    sigmadb - New Sigma Exception (private function)
.DESCRIPTION
    Creates new exception for a sigma rule in the database
.EXAMPLE
    PS C:\> New-PrivSigmaException -Id '1' -Operator 'nand' -SearchId 'filter' -Filter '{"LogonType":9,"user.name":"user1"} -Database $db'
    Creates new exception for sigma rule '1' in Database $db with the following YAML structure:
        filter:
            LogonType: 9
            user.name: 'user1'
        [...]
        condition: [...] and not filter
.INPUTS
    Id: Sigma rule ID
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
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

function New-PrivSigmaException {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
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
        switch ($Operator) {
            "nand" { $Operator = 'and not'}
            "nor" { $Operator = 'or not' }
        }

        $parameters = @{
            id       = $null
            operator = $Operator
            searchid = $SearchId
            filter   = $Filter
            ruleid   = $Id
        }

        $insert = "INSERT INTO exception VALUES (@id, @operator, @searchid, @filter, @ruleid)"

        if ($PSCmdlet.ShouldProcess($db.database, $insert)) {
            $db.Update($insert, $parameters)
        }
    }

    end {
        # nothing to do
    }
}