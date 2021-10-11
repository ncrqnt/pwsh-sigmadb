<#
.SYNOPSIS
    sigmadb - import sigma rule to db
.DESCRIPTION
    Import sigma rule into sqlite3 database
.EXAMPLE
    PS C:\> Import-SigmaRule -Path .\rules\windows -Database .\windows_rules.db -Recurse
    Gets all sigma rules (.yml) from .\rules\windows and subfolders (recurse) and
    imports them all into the database .\windows_rules.db.
    If the database doesn't exist, it'll be created.
.INPUTS
    Path: Path to YML-file or folder
    LiteralPath: Path to YML file or folder as is, no wildcards
    Database: Path to sqlite3 database
    Recurse: Switch to recurse folder in Path
    Disable: Switch to disable the rule (used to prevent "new rule" spam on update)
    Force: Updates/Overwrites existing rules
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.2.3   22.09.2021  ncrqnt      Changed call of SigmaDB class
    1.2.2   16.09.2021  ncrqnt      Restructure of config file
    1.2.1   16.09.2021  ncrqnt      Removed support for multiple documents
    1.2.0   15.09.2021  ncrqnt      Added support for disabling rules
    1.1.0   13.09.2021  ncrqnt      Added config file (currently for DB and rules/export folder)
                                    Changed Database parameter to Config
    1.0.3   13.09.2021  ncrqnt      Removed LiteralPath
    1.0.2   07.09.2021  ncrqnt      Added database class (SigmaDB)
    1.0.1   07.09.2021  ncrqnt      Added description
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

function Import-SigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to one locations.")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$Config = '.\sigmadb\config.json',
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        [Parameter(Mandatory = $false)]
        [switch]$Disable,
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        [Parameter(Mandatory = $false)]
        [switch]$NoProgressBar = $false
    )

    begin {
        $cfg = Get-PrivSigmaConfig -Config $Config
        $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
    }

    process {
        $item = Get-Item $path
        # check if file or directory
        if ($item.PSIsContainer) {
            # is container
            if ($Recurse) {
                $files = Get-ChildItem -Path "$path\*" -Recurse -Include *.yml, *.yaml
            }
            else {
                $files = Get-ChildItem -Path "$path\*" -Include *.yml, *.yaml
            }

            $i = 1
            foreach ($file in $files) {
                Copy-Item -Path $file -Destination $cfg.Folders.Rules | Out-Null
                $file = Get-Item "$($cfg.Folders.Rules)\$($file.Name)"
                $rule = Get-Content $file.FullName -Raw -Encoding utf8 | ConvertFrom-Yaml -Ordered -AllDocuments

                if ($null -eq $rule.id -or $null -ne $rule.action) {
                    Write-Warning "Rules without id or with multiple documents are not supported."
                    return
                }
                $max = $files.Count
                $now = '{0:d3}' -f $i
                $percent = 100 / $max * $i
                $name = $rule.title
                if (-not $NoProgressBar) {
                    Write-Progress -Activity "Importing" -Status "$now / $max completed" -PercentComplete $percent -CurrentOperation "Rule: $name"
                }
                Import-PrivSigmaRule -File $file -Rule $rule -Database $db -Config $cfg -Disable:$Disable -Force:$Force
                $i++
            }
        }
        else {
            $file = Get-Item $path
            if ($file.Extension -match '[.yml|.yaml]') {
                Copy-Item -Path $file -Destination $cfg.Folders.Rules | Out-Null
                $file = Get-Item "$($cfg.Folders.Rules)\$($file.Name)"
                $rule = Get-Content $file.FullName -Raw -Encoding utf8 | ConvertFrom-Yaml -Ordered

                if ($null -eq $rule.id -or $null -ne $rule.action) {
                    Write-Warning "Rules without id or with multiple documents are not supported."
                    return
                }

                Import-PrivSigmaRule -File $file -Rule $rule -Database $db -Config $cfg -Disable:$Disable -Force:$Force -InformationAction Continue
            }
            else {
                $extension = ($file.Extension).Split('.')[1].ToUpper()
                Write-Warning -Message "File type '$extension' is not supported. Please use a YAML/YML file."
            }
        }
    }

    end {
        $db.Close()
    }
}