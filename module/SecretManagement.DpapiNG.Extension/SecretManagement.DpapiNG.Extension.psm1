# Copyright: (c) 2023, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$importModule = Get-Command -Name Import-Module -Module Microsoft.PowerShell.Core

# Get the name of the module without .Extension
$currentModuleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$moduleName = $currentModuleName.Substring(0, $currentModuleName.Length - 10)

if ($PSVersionTable.PSVersion.Major -eq 5) {
    # PowerShell 5.1 has no concept of an Assembly Load Context so it will
    # just load the module assembly directly.

    $innerMod = if ('SecretManagement.DpapiNG.Module.GetSecretCommand' -as [type]) {
        $modAssembly = [SecretManagement.DpapiNG.Module.GetSecretCommand].Assembly
        &$importModule -Assembly $modAssembly -Force -PassThru
    }
    else {
        $modPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', 'net472', "$moduleName.Module.dll")
        &$importModule -Name $modPath -ErrorAction Stop -PassThru
    }
}
else {
    # This is used to load the shared assembly in the Default ALC which then sets
    # an ALC for the moulde and any dependencies of that module to be loaded in
    # that ALC.

    if (-not ('SecretManagement.DpapiNG.LoadContext' -as [type])) {
        Add-Type -Path ([System.IO.Path]::Combine($PSScriptRoot, 'bin', 'net6.0', "$moduleName.dll"))
    }

    $mainModule = [SecretManagement.DpapiNG.LoadContext]::Initialize()
    $innerMod = &$importModule -Assembly $mainModule -Force -PassThru
}

# The way SecretManagement runs doesn't like that the needed functions are part
# of an nested module of this one. This is a hack to ensure it's exposed here
# properly.
$addExportedCmdlet = [System.Management.Automation.PSModuleInfo].GetMethod(
    'AddExportedCmdlet',
    [System.Reflection.BindingFlags]'Instance, NonPublic'
)
foreach ($cmd in $innerMod.ExportedCommands.Values) {
    $addExportedCmdlet.Invoke($ExecutionContext.SessionState.Module, @(, $cmd))
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
