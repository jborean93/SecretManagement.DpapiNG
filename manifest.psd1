@{
    DotnetProject = 'SecretManagement.DpapiNG.Module'
    InvokeBuildVersion = '5.11.3'
    PesterVersion = '5.6.1'
    BuildRequirements = @(
        @{
            ModuleName = 'Microsoft.PowerShell.PSResourceGet'
            ModuleVersion = '1.0.5'
        }
        @{
            ModuleName = 'OpenAuthenticode'
            RequiredVersion = '0.4.0'
        }
        @{
            ModuleName = 'platyPS'
            RequiredVersion = '0.14.2'
        }
    )
    TestRequirements = @(
        @{
            ModuleName = 'Microsoft.PowerShell.SecretManagement'
            ModuleVersion = '1.1.2'
        }
    )
}
