<#
.SYNOPSIS
    sigmadb - convert sigma rule from database to yaml (private function)
.DESCRIPTION
    Private function for converting sigma rule from sigmadb to yaml with the custom exceptions
.EXAMPLE
    PS C:\> ConvertTo-PrivSigmaYaml -Rule $rule -Database $db
    Converts the selected rule from the defined database to a yaml file
.INPUTS
    Rule: DataRow from SQL query
    Database: SigmaDB class object
.OUTPUTS
    YAML file
.NOTES
    Author:     ncrqnt
    Date:       08.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.1.0   22.09.2021  ncrqnt      Removed file_path and replaced with Rules path in config file
    1.0.1   16.09.2021  ncrqnt      Removed support for multiple documents
    1.0.0   08.09.2021  ncrqnt      Initial creation
#>

#Requires -Module 'SimplySql'
#Requires -Module 'powershell-yaml'

function ConvertTo-PrivSigmaYaml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.DataRow]$Rule,
        [Parameter(Mandatory = $true)]
        [SigmaDB]$Database,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
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
        # Get exceptions
        $exceptions = $db.Query("SELECT * FROM exception WHERE rule_id = @id", @{ id = $Rule.id })

        # Get file data
        $yaml = Get-Content "$($Config.Folders.Rules)\$($Rule.file_name)" -Raw -Encoding utf8
        $dict = $yaml | ConvertFrom-Yaml -Ordered

        # Transform case
        if ($Config.CaseSensitivity.Enabled) {
            $selections = $dict.detection.Keys | Where-Object { $_ -notin ('condition', 'timeframe') }

            $type_orderedDict = [System.Collections.Specialized.OrderedDictionary]
            $type_genericList = [System.Collections.Generic.List`1[[System.Object, System.Private.CoreLib, Version = 5.0.0.0, Culture = neutral, PublicKeyToken = 7cec85d7bea7798e]]]

            foreach ($selection in $selections) {
                if ($null -ne $dict.detection.$selection.Keys) {
                    $keys = $dict.detection.$selection.Keys.Clone()
                }

                if ($dict.detection.$selection -is $type_orderedDict) {
                    # Selection is a ordered dictionary ('AND' / unique field names)

                    foreach ($key in $keys) {
                        $field = $key -replace '\|.*',''
                        if ($Config.CaseSensitivity.AllFields -or ($field -in $Config.CaseSensitivity.Fields)) {
                            if ($Config.CaseSensitivity.Mode -eq 'uppercase') {
                                $newCase = $dict.detection.$selection.$key.ToUpper()
                            }
                            else {
                                $newCase = $dict.detection.$selection.$key.ToLower()
                            }

                            $dict.detection.$selection.$key = $newCase
                        }
                    }
                }
                elseif ($dict.detection.$selection -is $type_genericList) {
                    # Selection is a generic list ('OR' / duplicate field names possible)
                    foreach ($item in $dict.detection.$selection) {
                        $index = $dict.detection.$selection.IndexOf($item)

                        if ($item -is $type_orderedDict) {
                            $keys = $item.Keys.Clone()

                            foreach ($key in $keys) {
                                $field = $key -replace '\|.*',''
                                if ($Config.CaseSensitivity.AllFields -or ($field -in $Config.CaseSensitivity.Fields)) {
                                    if ($Config.CaseSensitivity.Mode -eq 'uppercase') {
                                        $newCase = $dict.detection.$selection[$index].$key.ToUpper()
                                    }
                                    else {
                                        $newCase = $dict.detection.$selection[$index].$key.ToLower()
                                    }

                                    $dict.detection.$selection[$index].$key = $newCase
                                }
                            }
                        }
                    }
                }
            }

            <# if ($dict.detection.$selection.Count -gt 1) {
                        # Array
                        Write-Verbose $selection
                        $index = $dict.detection.$selection.IndexOf($item)
                        $newCase = $item[0].ToLower()
                        $dict.detection.$selection[$index][0] = $newCase
                    }
                    else {
                        # single item
                        $newCase = $item[0].ToLower()
                        $dict.detection.$selection[0] = $newCase
                    } #>
            <# $key = $field -replace '\|.*', ''
                    $index = $dict.detection.$selection.IndexOf($item)

                    if ($Config.CaseSensitivity.AllFields -or ($key -in $Config.CaseSensitivity.Fields)) {
                        if ($dict.detection.$selection.Count -gt 1) {
                            if ($Config.CaseSensitivity.Mode -eq 'uppercase') {
                                $newCase = $dict.detection.$selection[$index][$field].ToUpper()
                            }
                            else {
                                $newCase = $dict.detection.$selection[$index][$field].ToLower()
                            }

                            $dict.detection.$selection[$index][$field] = $newCase
                        }
                        else {
                            if ($Config.CaseSensitivity.Mode -eq 'uppercase') {
                                $newCase = $dict.detection.$selection[$index].ToUpper()
                            }
                            else {
                                $newCase = $dict.detection.$selection[$index].ToLower()
                            }

                            $dict.detection.$selection[$index] = $newCase
                        }
                    } #>
        }


        # Add exceptions to yaml
        if ($exceptions.Count -gt 0) {
            $yaml = (Add-PrivSigmaException -RuleDict $dict -ExceptionList $exceptions) | ConvertTo-Yaml
        }
        else {
            $yaml = $dict | ConvertTo-Yaml
        }

        return $yaml
    }

    end {
        # nothing to do
    }
}