# Copyright: (c) 2023, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    # RootModule = 'SecretManagement.DpapiNG.Extension.psm1'
    RootModule = 'bin/net6.0/SecretManagement.DpapiNG.Module.dll'
    ModuleVersion = '0.1.0'
    GUID = '167d7de5-1d14-4eb4-9316-5a5aedbb1f30'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2023 Jordan Borean. All rights reserved.'
    FunctionsToExport = @()
    CmdletsToExport = @(
        'Get-Secret'
        'Get-SecretInfo'
        'Remove-Secret'
        'Set-Secret'
        'Test-SecretVault'
    )
    # CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
