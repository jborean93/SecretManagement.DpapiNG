# Copyright: (c) 2023, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule = 'SecretManagement.DpapiNG.Extension.psm1'
    ModuleVersion = ''
    GUID = '167d7de5-1d14-4eb4-9316-5a5aedbb1f30'
    Author = ''
    CompanyName = ''
    Copyright = ''
    FunctionsToExport = @()
    CmdletsToExport = @(
        # Used for SecretManagement
        'Get-Secret'
        'Get-SecretInfo'
        'Remove-Secret'
        'Set-Secret'
        'Test-SecretVault'
    )
    VariablesToExport = @()
    AliasesToExport = @()
}
