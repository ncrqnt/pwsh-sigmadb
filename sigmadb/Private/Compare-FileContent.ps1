<#
.SYNOPSIS
    sigmadb - Compare file content (private)
.DESCRIPTION
    Compare file content and show differences (with color)
.NOTES
    Author:     ncrqnt
    Date:       14.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.1   17.09.2021  ncrqnt      Changed SyncWindow to 1 in order to compare line-by-line
    1.0.0   14.09.2021  ncrqnt      Initial creation
#>

function Compare-FileContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ReferenceObject,
        [Parameter(Mandatory = $true)]
        [string]$DifferenceObject
    )

    $old = Get-Content $ReferenceObject -Encoding utf8 | ForEach-Object { $i = 1 } { New-Object psobject -Property @{LineNum = $i; Text = $_ }; $i++ }
    $new = Get-Content $DifferenceObject -Encoding utf8 | ForEach-Object { $i = 1 } { New-Object psobject -Property @{LineNum = $i; Text = $_ }; $i++ }

    $compare = Compare-Object -ReferenceObject $old -DifferenceObject $new -Property Text -PassThru -IncludeEqual -SyncWindow 1 | Sort-Object LineNum

    foreach ($line in $compare) {
        switch ($line.SideIndicator) {
            "==" { Write-Output "  $($line.Text)" }
            "<=" { Write-Host "- $($line.Text)" -ForegroundColor DarkRed }
            "=>" { Write-Host "+ $($line.Text)" -ForegroundColor DarkGreen }
        }
    }
}