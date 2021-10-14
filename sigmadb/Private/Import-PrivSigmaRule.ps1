<#
.SYNOPSIS
    sigmadb - import sigma rule to db (private)
.DESCRIPTION
    Private function for Import-SigmaRule
.EXAMPLE
    PS C:\> Import-PrivSigmaRule -File $rulefile -Rule $rule -Database $db -Force
    Reads meta data from the $rulefile and $rule, add them to a hashtable and inserts/updates the SQL table 'rule'.
    With the -Force switch, it'll update/override existing rules.
.INPUTS
    -File: FileInfo from Get-Item / Item of Get-ChildItem
    -Rule: Ordered Dictionary from ConvertFrom-Yaml
    -Database: SigmaDB class object
    -Force: Switch to update/override existing rules
.OUTPUTS
    None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.2.0   22.09.2021  ncrqnt      Removed file_path and changed output text
    1.1.1   16.09.2021  ncrqnt      Removed support for multiple documents
    1.1.0   15.09.2021  ncrqnt      Added support for disabling rules
    1.0.7   14.09.2021  ncrqnt      Small fixes
    1.0.6   08.09.2021  ncrqnt      Better handling/indicator of is_multidoc tag
    1.0.5   08.09.2021  ncrqnt      Fixed conflicting variable name
    1.0.4   08.09.2021  ncrqnt      Fixed an issue condition always fail because DB class never returns $null
    1.0.3   07.09.2021  ncrqnt      Removed output type
    1.0.2   07.09.2021  ncrqnt      Added database class
    1.0.1   07.09.2021  ncrqnt      Added description, Removed output from Invoke-SqlUpdate
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

#Requires -Module 'SimplySql'
#Requires -Module 'powershell-yaml'

function Import-PrivSigmaRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$Rule,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory = $false)]
        [switch]$Disable,
        [Parameter(Mandatory = $false)]
        [switch]$Force
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
        try {
            # Find custom tag
            $customTags = $Config.RuleSettings.CustomTags
            $isCustom = 0
            if ($customTags.Count -gt 0) {
                foreach ($customTag in $customTags) {
                    if ($customTag -in $Rule.tags) {
                        $isCustom = 1
                        break
                    }
                }
            }

            $date = Get-Date -Format 'o'
            $filehash = (Get-FileHash $File.FullName -Algorithm SHA256).Hash.ToLower()
            $parameters = @{
                id          = $Rule.id
                title       = $Rule.title
                fileName    = $File.Name
                creation    = (Get-Date $Rule.date -UFormat %F)
                modified    = $null -ne $Rule.modified ? (Get-Date $Rule.modified -UFormat %F) : (Get-Date $Rule.date -UFormat %F)
                fileHash    = $filehash
                isEql       = $Rule.detection.timeframe ? 1 : 0
                isCustom    = $isCustom
                isEnabled   = $Disable ? 0 : 1
                installDate = $date
                updateDate  = $date
                ignoreHash  = $filehash
            }

            $result = $db.Query("SELECT * FROM rule WHERE id = @id", @{id = $Rule.id })[0]

            if ($null -eq $result) {
                $insert = " INSERT INTO rule
                        VALUES      (@id,
                                    @title,
                                    @fileName,
                                    @creation,
                                    @modified,
                                    @filehash,
                                    @isEql,
                                    @isCustom,
                                    @isEnabled,
                                    @ignoreHash,
                                    @installDate,
                                    @updateDate)"
                $db.Update($insert, $parameters)
                Write-Information "Rule imported: '$($Rule.title)'"
            }
            else {
                if ($Force) {
                    $update = " UPDATE  rule
                            SET     title = @title,
                                    file_name = @fileName,
                                    creation_date = @creation,
                                    modified_date = @modified,
                                    file_hash = @fileHash,
                                    is_eql = @isEql,
                                    is_custom = @isCustom,
                                    is_enabled = @isEnabled,
                                    ignore_hash = @ignoreHash,
                                    update_date = @updateDate
                            WHERE   id = @id"
                    $db.Update($update, $parameters)
                    Write-Information "Rule updated: '$($Rule.title)'"
                }
                else {
                    Write-Warning -Message "Rule '$($Rule.title)' already exists. Use -Force to update/override."
                }
            }
            return
        }
        catch {
            Write-Error -Message "Could not import rule '$($Rule.title)': $_"
            return
        }
    }

    end {
        # nothing to do
    }
}