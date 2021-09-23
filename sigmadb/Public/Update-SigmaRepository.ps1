<#
.SYNOPSIS
    sigmadb - Update sigma repository
.DESCRIPTION
    Updates/Downloads sigma repository either with git or via download
.EXAMPLE
    PS C:\> Update-SigmaRepository -SigmaRepo .\sigma
    Either git clone/pull or download sigma repo to the desired location
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Author:     ncrqnt
    Date:       10.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.1   10.09.2021  ncrqnt      Added parameter validation
    1.1.0   10.09.2021  ncrqnt      Added description
                                    Added absoulte path of SigmaRepo
                                    Delete zip file after extraction
    1.0.0   10.09.2021  ncrqnt      Initial creation
#>

function Update-SigmaRepository {
    [CmdletBinding(SupportsShouldProcess ,ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (Test-Path $_ -PathType Container -IsValid) { $true } else { throw "$_ is not a valid path." } })]
        [string]$SigmaRepo
    )

    begin {
        # check if git exists
        try {
            (git.exe --version) | Out-Null
            [bool]$git = $true
        }
        catch {
            [bool]$git = $false
        }
        $currentloc = Get-Location
    }

    process {
        $path = (Get-Item $SigmaRepo).Path
        $root = Split-Path $path

        if (Test-Path $path) {
            $action = 'pull'
        }
        else {
            if (-not (Test-Path $root)) {
                New-Item -Path $root -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
            }
            $action = 'clone'
        }

        Set-Location $root

        if ($git) {
            if ($action -eq 'pull') {
                Set-Location $path
            }
            if ($PSCmdlet.ShouldProcess("$path", "git.exe $action https://github.com/SigmaHQ/sigma.git")) {
                git.exe $action https://github.com/SigmaHQ/sigma.git
            }
        }
        else {
            if ($action -eq 'pull') {
                $date = Get-Date -Format FileDate
                $oldrepo = "$($path).old-$date"
                Rename-Item -Path $path -NewName $oldrepo -WhatIf:$WhatIfPreference
            }

            if ($PSCmdlet.ShouldProcess("https://github.com/SigmaHQ/sigma/archive/refs/heads/master.zip", "Download Item")) {
                Invoke-WebRequest -Uri "https://github.com/SigmaHQ/sigma/archive/refs/heads/master.zip" -OutFile "$root\sigma.zip"
            }

            Expand-Archive -Path "$root\sigma.zip" -DestinationPath $root -WhatIf:$WhatIfPreference
            Rename-Item -Path "$root\sigma-master" -NewName "sigma" -WhatIf:$WhatIfPreference
            Remove-Item -Path "$root\sigma.zip" -WhatIf:$WhatIfPreference
        }
    }

    end {
        Set-Location $currentloc
    }
}