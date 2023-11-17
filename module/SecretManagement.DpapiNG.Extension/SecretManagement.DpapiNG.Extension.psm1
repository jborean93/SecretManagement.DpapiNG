# Copyright: (c) 2023, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$importModule = Get-Command -Name Import-Module -Module Microsoft.PowerShell.Core
# $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$moduleName = "SecretManagement.DpapiNG"

if ($PSVersionTable.PSVersion.Major -eq 5) {
    # PowerShell 5.1 has no concept of an Assembly Load Context so it will
    # just load the module assembly directly.

    if (-not ('SecretManagement.DpapiNG.Module.GetSecretCommand' -as [type])) {
        &$importModule ([IO.Path]::Combine($PSScriptRoot, 'bin', 'net472', "$moduleName.Module.dll")) -ErrorAction Stop
    }
    else {
        &$importModule -Force -Assembly ([SecretManagement.DpapiNG.Module.GetSecretCommand].Assembly)
    }
}
else {
    # This is used to load the shared assembly in the Default ALC which then sets
    # an ALC for the moulde and any dependencies of that module to be loaded in
    # that ALC.

    if (-not ('SecretManagement.DpapiNG.Module.GetSecretCommand' -as [type])) {
        &$importModule ([IO.Path]::Combine($PSScriptRoot, 'bin', 'net6.0', "$moduleName.Module.dll")) -ErrorAction Stop
    }
    else {
        &$importModule -Force -Assembly ([SecretManagement.DpapiNG.Module.GetSecretCommand].Assembly)
    }

    # $isReload = $true
    # if (-not ('SecretManagement.DpapiNG.LoadContext' -as [type])) {
    #     $isReload = $false
    #     Add-Type -Path ([System.IO.Path]::Combine($PSScriptRoot, 'bin', 'net6.0', "$moduleName.dll"))
    # }

    # $mainModule = [SecretManagement.DpapiNG.LoadContext]::Initialize()
    # &$importModule -Force -Assembly $mainModule

    # if ($isReload) {
    #     # Bug in pwsh, Import-Module in an assembly will pick up a cached instance
    #     # and not call the same path to set the nested module's cmdlets to the
    #     # current module scope.
    #     # https://github.com/PowerShell/PowerShell/issues/20710
    #     $addExportedCmdlet = [System.Management.Automation.PSModuleInfo].GetMethod(
    #         'AddExportedCmdlet',
    #         [System.Reflection.BindingFlags]'Instance, NonPublic'
    #     )
    #     foreach ($cmd in $alcModule.ExportedCommands.Values) {
    #         $addExportedCmdlet.Invoke($ExecutionContext.SessionState.Module, @(, $cmd))
    #     }
    # }
}

# Use this for testing that the dlls are loaded correctly and outside the Default ALC.
# [System.AppDomain]::CurrentDomain.GetAssemblies() |
#     Where-Object { $_.GetName().Name -like "*DpapiNG*" } |
#     ForEach-Object {
#         $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_)
#         [PSCustomObject]@{
#             Name = $_.FullName
#             Location = $_.Location
#             ALC = $alc
#         }
#     } | Format-List
