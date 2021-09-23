<#
.SYNOPSIS
    sigmadb - Add custom exception to sigma rule (private function)
.DESCRIPTION
    Private function called by ConvertTo-PrivSigmaYaml
    in order to add the custom exceptions to the selected sigma rule
.EXAMPLE
    PS C:\> Add-PrivSigmaException -RuleYaml $yaml -ExceptionList $exceptions
    Adds the exceptions from $exception to the sigma rule $yaml
.INPUTS
    RuleYaml: Ordered Dictionary of the sigma rule (from ConvertFrom-Yaml -Ordered)
    ExceptionList: Array of all exceptions of the selected rule (from SQL query)
.OUTPUTS
    System.Collections.Specialized.OrderedDictionary
.NOTES
    Author:     ncrqnt
    Date:       09.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.0.0   09.09.2021  ncrqnt      Initial creation
#>

function Add-PrivSigmaException {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$RuleDict,
        [Parameter(Mandatory = $true)]
        [array]$ExceptionList
    )

    $yaml = $RuleDict
    $exceptions = $ExceptionList

    if (-not $yaml.detection) {
        $yaml.Add('detection', [ordered]@{}) | Out-Null
    }

    foreach ($exc in $exceptions) {
        $key = $exc.search_identifier
        $value = $exc.filter | ConvertFrom-Json -AsHashtable
        # Add exception to existing filter
        if ($yaml.detection.$key) {
            $yaml.detection.$key += $value
        }
        else {
            # Add new exception to yaml 'detection' tree
            if ($yaml.detection.condition) {
                $index = ($yaml.detection).Count - 1
                $yaml.detection.condition += " $($exc.operator) $($exc.search_identifier)"
            }
            else {
                $index = ($yaml.detection).Count
            }

            $yaml.detection.Insert($index, $key, $value) | Out-Null
        }
    }

    return $yaml
}