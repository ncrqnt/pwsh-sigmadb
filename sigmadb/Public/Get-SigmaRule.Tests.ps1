BeforeAll {
    #region Load mmodule
    $modulePath = "$PSScriptRoot\..\sigmadb.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    #endregion
}

Describe "Get-SigmaRule" {
    Context "Database with data" {
        BeforeAll {
            $config = "$TestDrive\sigmadb\config.yml"
            Import-SigmaRule -Path ".\testing\rules" -Config $config -NoProgressBar
        }
        It "should list all rules found in database" {
            $result = Get-SigmaRule -Config $config
            $result.Count | Should -BeGreaterThan 1
            $result | Should -ExpectedType [System.Collections.Specialized.OrderedDictionary]
        }

        It "should get only specific rule in database" {
            $id = '4976aa50-8f41-45c6-8b15-ab3fc10e79ed'
            $result = Get-SigmaRule -Id $id -Config $config
            $result | Should -ExpectedType [System.Collections.Specialized.OrderedDictionary]
            $result.id | Should -Be $id
        }

        It 'should return $null if non-existing id is passed' {
            (Get-SigmaRule -Id 'x' -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id '1' -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id '@' -Config $config | Out-Null) | Should -BeNullOrEmpty
        }
    }

    Context "No/Empty database" {
        BeforeAll {
            # create empty database
            $config = "$TestDrive\sigmadb\config.yml"
            Get-SigmaRule -Config $config
        }
        It 'should create file structure' {
            Test-Path $config | Should -BeTrue
            $path = Split-Path $config
            Test-Path "$path\rules" | Should -BeTrue
            Test-Path "$path\exports" | Should -BeTrue
            Test-Path "$path\database.db" | Should -BeTrue
        }

        It 'should always return $null' {
            (Get-SigmaRule -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id '4976aa50-8f41-45c6-8b15-ab3fc10e79ed' -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id 'x' -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id '1' -Config $config | Out-Null) | Should -BeNullOrEmpty
            (Get-SigmaRule -Id '@' -Config $config | Out-Null) | Should -BeNullOrEmpty
        }

        It 'should return $null if non-existing id is passed' {
            Get-SigmaRule -Config $config | Should -BeNullOrEmpty
        }
    }

    Context "Output Types" {
        BeforeAll {
            $config = "$TestDrive\sigmadb\config.yml"
            Import-SigmaRule -Path ".\testing\rules" -Config $config -NoProgressBar
        }
        It "should output in an OrderedDictionary" {
            Get-SigmaRule -Id '4976aa50-8f41-45c6-8b15-ab3fc10e79ed' -Config $config | Should -ExpectedType [System.Collections.Specialized.OrderedDictionary]
            (Get-SigmaRule -Config $config)[0] | Should -ExpectedType [System.Collections.Specialized.OrderedDictionary]
        }

        It "should output in JSON" {
            $result_one = Get-SigmaRule -Id '4976aa50-8f41-45c6-8b15-ab3fc10e79ed' -Config $config -Type JSON
            $result_all = Get-SigmaRule -Config $config -Type JSON

            $result_one | Should -ExpectedType [System.String]
            Test-Json $result_one | Should -BeTrue

            $result_all[0] | Should -ExpectedType [System.String]
            Test-Json $result_all[0] | Should -BeTrue

        }

        It "should output in YAML" {
            Get-SigmaRule -Id '4976aa50-8f41-45c6-8b15-ab3fc10e79ed' -Config $config -Type YAML | Should -ExpectedType [System.String]
            (Get-SigmaRule -Config $config -Type YAML)[0] | Should -ExpectedType [System.String]

        }
    }
}