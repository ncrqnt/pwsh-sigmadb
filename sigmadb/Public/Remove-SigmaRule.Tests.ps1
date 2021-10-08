BeforeAll {
    #region Load mmodule
    $modulePath = "$PSScriptRoot\..\sigmadb.psm1"
    $moduleName = (($modulePath | Split-Path -Leaf) -replace '.psm1')
    @(Get-Module -Name $moduleName).where({ $_.version -ne '0.0' }) | Remove-Module
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    #endregion
}

