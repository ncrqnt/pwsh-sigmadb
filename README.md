# pwsh-sigmadb
`pwsh-sigmadb` is a SIGMA Rule Mangement Tool. It allows to manage and update sigma rules without affecting custom false-positive exceptions.

# Table of Contents
- [pwsh-sigmadb](#pwsh-sigmadb)
- [Table of Contents](#table-of-contents)
- [Wiki](#wiki)
- [Installation](#installation)
  - [Using PowerShellGet (not yet available)](#using-powershellget-not-yet-available)
  - [Using the repository](#using-the-repository)
- [Usage](#usage)
  - [Import-SigmaRule](#import-sigmarule)
  - [Get-SigmaRule](#get-sigmarule)
  - [Enable-SigmaRule / Disable-SigmaRule](#enable-sigmarule--disable-sigmarule)
  - [Remove-SigmaRule](#remove-sigmarule)
  - [Export-SigmaRule](#export-sigmarule)
  - [Update-SigmaRule](#update-sigmarule)
  - [New-SigmaException](#new-sigmaexception)
  - [Set-SigmaException](#set-sigmaexception)
  - [Remove-SigmaException](#remove-sigmaexception)
  - [Update-SigmaRepository](#update-sigmarepository)

# Wiki
For more information look up the [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki).


# Installation

## Using PowerShellGet
Open a PowerShell and type:
```powershell
Install-Module -Name 'sigmadb' -AllowPrerelease
```

## Using the repository
Clone this GitHub repository, open a PowerShell inside the folder and type:
```powershell
# Install dependencies
Install-Module -Name 'SimplySql'
Install-Module -Name 'powershell-yaml'

# Load sigmadb module inside the repository
Import-Module '.\sigmadb\sigmadb.psd1'
```

# Usage

## Import-SigmaRule
```
Import-SigmaRule [-Path] <String> [-Config <String>] [-Recurse] [-Disable] [-Force] [<CommonParameters>]
```

| Parameter |  Type  | Mandatory | Description                                                                                                              |
| --------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Path`    | String |    Yes    | Folder of sigma rules to import or single sigma rule file                                                                |
| `Config`  | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `Recurse` | Switch |    No     | Recurse folder defined in Path to also import rules in subfolders                                                        |
| `Disable` | Switch |    No     | Mark all rules as disabled (explicit update and export necessary)                                                        |
| `Force`   | Switch |    No     | Overwrite existing rules                                                                                                 |

```powershell
# Example 1:
# Imports all rules from .\sigma\rules\windows and subfolders. Config file is generated automatically and located in .\sigmadb\config.yml
Import-SigmaRule -Path .\sigma\rules\windows -Recurse

# Example 2:
# Imports all rules from .\sigma\rules\windows\builtin but disabled them (explicit update and export only)
Import-SigmaRule -Path .\sigma\rules\windows\builtin -Config C:\sigmarules\config.yml -Disable
```

## Get-SigmaRule
```
Get-SigmaRule [[-Id] <String>] [[-Config] <String>] [[-Type] <String>] [<CommonParameters>]
```

| Parameter |  Type  | Mandatory | Description                                                                                                              |
| --------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`      | String |    No     | Rule ID. If not given, all rules are affected                                                                            |
| `Config`  | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `Type`    | Switch |    No     | Output type: 'Plain', 'JSON' or 'YAML'. Default: 'Plain' (Ordered Dictionary)                                            |

```powershell
# Example 1:
# Output all existing sigma rules in the database as ordered dictionary
Get-SigmaRule

# Example 2:
# Shows the rule with id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' in YAML (basically how a sigma rule file looks)
Get-SigmaRule -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' -Type YAML
```

## Enable-SigmaRule / Disable-SigmaRule
```
Enable-SigmaRule [-Id] <String> [[-Config] <String>] [<CommonParameters>]
Disable-SigmaRule [-Id] <String> [[-Config] <String>] [<CommonParameters>]
```

| Parameter |  Type  | Mandatory | Description                                                                                                              |
| --------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`      | String |    Yes    | Rule ID                                                                                                                  |
| `Config`  | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |

```powershell
# Example 1:
# Disables sigma rule (update and export have to be done with -IncludeDisabled)
Disable-SigmaRule -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53'

# Example 2:
# Enables sigma rule
Enable-SigmaRule -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53'
```

## Remove-SigmaRule
```
Remove-SigmaRule [-Id] <String> [[-Config] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter |  Type  | Mandatory | Description                                                                                                              |
| --------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`      | String |    Yes    | Rule ID                                                                                                                  |
| `Config`  | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `WhatIf`  | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                |
| `Confirm` | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                             |

```powershell
# Example 1:
# Removes rule from the database and deletes local copy
Remove-SigmaRule -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53'
```

## Export-SigmaRule
```
Export-SigmaRule [-Id <String>] [-Destination <String>] [-Config <String>] -SigmaRepo <String> [-IncludeDisabled] [<CommonParameters>]
Export-SigmaRule [-Id <String>] [-Destination <String>] [-Config <String>] -SigmaRepo <String> [-IncludeDisabled] -Elastic [-BackendConfig <String>] [<CommonParameters>]
```

| Parameter         |  Type  | Mandatory | Description                                                                                                              |
| ----------------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`              | String |    No     | Rule ID. If not given, all rules affected (except disabled)                                                              |
| `Destination`     | String |    No     | Export folder. Default inside `config.json`                                                                              |
| `Config`          | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `SigmaRepo`       | String |    Yes    | Path to the cloned (sigma repository)[https://github.com/SigmaHQ/sigma]                                                  |
| `IncludeDisabled` | Switch |    No     | Include disabled rules                                                                                                   |

Elastic Parameters:

| Parameter       |  Type  | Mandatory | Description                                                                         |
| --------------- | :----: | :-------: | ----------------------------------------------------------------------------------- |
| `Elastic`       | Switch |    Yes    | Convert automatically to elasticsearch rule (requires `sigmac` from the sigma repo) |
| `BackendConfig` | String |    No     | Path to backend config for elasticsearch converter                                  |

```powershell
# Example 1:
# Exports rule '353aabf7-e72c-4aeb-b376-0ab45f94ad53' to the default path defined in config.json
Export-SigmaRule -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' -SigmaRepo .\sigma

# Example 2:
# Exports all rules (including the disabled rules) to .\export and automatically convert them to a elasticsearch rule
Export-SigmaRule -Destination .\export -SigmaRepo .\sigma -IncludeDisabled -Elastic
```

## Update-SigmaRule
```
Update-SigmaRule [-RulesFolder] <String> [[-Config] <String>] [-IncludeDisabled] [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter         |  Type  | Mandatory | Description                                                                                                              |
| ----------------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `RulesFolder`     | String |    Yes    | Path to folder with the new rules                                                                                        |
| `Config`          | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `IncludeDisabled` | Switch |    No     | Include disabled rules                                                                                                   |
| `WhatIf`          | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                |
| `Confirm`         | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                             |

```powershell
# Example 1:
# Checks if the rule ids are in the database, if the file hash is different. If yes it prints the diff and a prompt to accept/decline the changes
Update-SigmaRule -RulesFolder .\new_rules

# Example 2:
# Updates all sigma rule  without confirming (basically the same as Import-SigmaRule -Force, but only for existing rules)
Update-SigmaRule -RulesFolder .\new_rules -Confirm:$false
```

## New-SigmaException
```
New-SigmaException [-Id] <String> [[-Operator] <String>] [[-SearchId] <String>] [-Filter] <String> [[-Config] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter  |  Type  | Mandatory | Description                                                                                                                             |
| ---------- | :----: | :-------: | --------------------------------------------------------------------------------------------------------------------------------------- |
| `Id`       | String |    Yes    | Rule ID                                                                                                                                 |
| `Operator` | String |    No     | Operator: 'and', 'nand', 'or', 'nor'. Default: 'nand' (not and)                                                                         |
| `SearchId` | String |    No     | Search identifier (see [SIGMA specification](https://github.com/SigmaHQ/sigma/wiki/Specification#search-identifier)). Default: 'filter' |
| `Filter`   | String |    Yes    | Filter/Rule/Exception in JSON (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Tutorial))                                       |
| `Config`   | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml`                |
| `WhatIf`   | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                               |
| `Confirm`  | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                                            |

```powershell
# Example 1:
# Adds an exception ("and not" detection) to the rule with the search identifier 'filter' and the detection filter.
New-SigmaException -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' -Operator 'nand' -SearchId 'filter' -Filter '{"LogonType": 8, "user.name": "testuser"}'
```

Assuming the detection of rule `353aabf7-e72c-4aeb-b376-0ab45f94ad53` would be:
```YAML
detection:
  selection:
     LogonType:
       - 4
       - 5
       - 8
       - 9
       - 11
  condition: selection
```

The resulting YAML file with the exception would look like this:
```YAML
detection:
  selection:
     LogonType:
       - 4
       - 5
       - 8
       - 9
       - 11
  filter:
    LogonType: 8
    "user.name": "testuser"
  condition: selection and not filter
```

## Set-SigmaException
```
Set-SigmaException [-Id] <String> [-SearchId] <String> [-Operator] <String> [-Filter] <String> [[-Config] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter  |  Type  | Mandatory | Description                                                                                                              |
| ---------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`       | String |    Yes    | Rule ID                                                                                                                  |
| `SearchId` | String |    Yes    | Search identifier (see [SIGMA specification](https://github.com/SigmaHQ/sigma/wiki/Specification#search-identifier))     |
| `Operator` | String |    Yes    | Operator: 'and', 'nand', 'or', 'nor'. Default: 'nand' (not and)                                                          |
| `Filter`   | String |    Yes    | Filter/Rule/Exception in JSON (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Tutorials))                        |
| `Config`   | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `WhatIf`   | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                |
| `Confirm`  | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                             |

```powershell
# Example 1:
# Sets the 'filter' search identifier ("filter") of the rule to the defined Filter
Set-SigmaException -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' -SearchId 'filter' -Operator 'nand' -Filter '{"LogonType": 5, "user.name": "svc_*"}'
```

From the example of [`New-SigmaException`](#new-sigmaexception), the resulting YAML would now look like:
```YAML
detection:
  selection:
     LogonType:
       - 4
       - 5
       - 8
       - 9
       - 11
  filter:
    LogonType: 5
    "user.name": "svc_*"
  condition: selection and not filter
```

## Remove-SigmaException
```
Remove-SigmaException [-Id] <String> [-SearchId] <String> [[-Config] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter  |  Type  | Mandatory | Description                                                                                                              |
| ---------- | :----: | :-------: | ------------------------------------------------------------------------------------------------------------------------ |
| `Id`       | String |    Yes    | Rule ID                                                                                                                  |
| `SearchId` | String |    Yes    | Search identifier (see [SIGMA specification](https://github.com/SigmaHQ/sigma/wiki/Specification#search-identifier))     |
| `Config`   | String |    No     | Path to `config.json` (see [wiki](https://github.com/ncrqnt/pwsh-sigmadb/wiki/Config)). Default: `.\sigmadb\config.yml` |
| `WhatIf`   | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                |
| `Confirm`  | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))                                             |

```powershell
# Example 1:
# Removes the filter with the search identifier 'filter' from the rule
Remove-SigmaException -Id '353aabf7-e72c-4aeb-b376-0ab45f94ad53' -SearchId 'filter'
```

## Update-SigmaRepository
```
Update-SigmaRepository [-SigmaRepo] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

| Parameter   |  Type  | Mandatory | Description                                                                               |
| ----------- | :----: | :-------: | ----------------------------------------------------------------------------------------- |
| `SigmaRepo` | String |    Yes    | Path to the cloned [sigma repo](https://github.com/SigmaHQ/sigma)                         |
| `WhatIf`    | Switch |    No     | Shows what it does, without doing something (see [ShouldProcess](https://bit.ly/3EyDs1R)) |
| `Confirm`   | Switch |    No     | Confirm before doing something (see [ShouldProcess](https://bit.ly/3EyDs1R))              |

```powershell
# Example 1:
# If git is installed: git pull / git clone it to the defined path
# If git not installed: download repo via https
Update-SigmaRepository -SigmaRepo .\sigma
```
