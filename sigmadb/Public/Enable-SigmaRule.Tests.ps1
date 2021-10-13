BeforeDiscovery {
    #region Load mmodule
    $modulePath = "$PSScriptRoot\..\sigmadb.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    #endregion
}

InModuleScope sigmadb {
    Describe "Enable-SigmaRule" {
        BeforeEach {
            $config = "$TestDrive\sigmadb\config.yml"
            Import-SigmaRule -Path ".\testing\rules" -Config $config -Disable -NoProgressBar
        }
        Context "Functionality Test" {
            It "should enable sigma rule" {
                $id = '4976aa50-8f41-45c6-8b15-ab3fc10e79ed'
                Enable-SigmaRule -Id $id -Config $config

                $cfg = Get-PrivSigmaConfig -Config $Config
                $db = New-Object -TypeName SigmaDB -ArgumentList $cfg.Files.Database
                $rule = $db.Query("SELECT * FROM rule WHERE id = @id", @{ id = $id })[0]
                $db.Close()

                $rule.is_enabled | Should -Be '1'
            }
        }
    }
}