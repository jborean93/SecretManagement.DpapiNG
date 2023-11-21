$moduleName = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'output', $moduleName)

$global:CurrentModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
if (-not $CurrentModule) {
    $global:CurrentModule = Import-Module $manifestPath -PassThru
}

if (-not (Get-Variable IsWindows -ErrorAction SilentlyContinue)) {
    # Running WinPS so guaranteed to be Windows.
    Set-Variable -Name IsWindows -Value $true -Scope Global
}

Function Global:Complete {
    [OutputType([System.Management.Automation.CompletionResult])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Expression
    )

    [System.Management.Automation.CommandCompletion]::CompleteInput(
        $Expression,
        $Expression.Length,
        $null).CompletionMatches
}

# The SID protector only works in a domain so some tests won't work in CI
$global:SIDUnvailable = $false
try {
    $null = ConvertTo-DpapiNGSecret foo -CurrentSid -ErrorAction Stop | ConvertFrom-DpapiNGSecret -ErrorAction Stop
}
catch {
    $global:SIDUnvailable = $true
}
