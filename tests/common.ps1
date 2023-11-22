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

Function global:New-WebCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Resource,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $UserName
    )

    $vault = [Windows.Security.Credentials.PasswordVault, Windows.Security.Credentials, ContentType = WindowsRuntime]::new()
    $vault.Add([Windows.Security.Credentials.PasswordCredential, Windows.Security.Credentials, ContentType = WindowsRuntime]::new(
            $Resource,
            $UserName,
            "ResourcePassword"
        ))
}

Function global:Remove-WebCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Resource,

        [Parameter(Mandatory)]
        [string]
        $UserName
    )

    $vault = [Windows.Security.Credentials.PasswordVault, Windows.Security.Credentials, ContentType = WindowsRuntime]::new()
    $vault.Remove($vault.Retrieve($Resource, $UserName))
}

if ($IsCoreCLR) {
    Function global:New-X509Certificate {
        [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Subject,

            [Parameter()]
            [System.Security.Cryptography.HashAlgorithmName]
            $HashAlgorithm = "SHA256"
        )

        $key = [System.Security.Cryptography.RSA]::Create(4096)
        $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            "CN=$Subject",
            $key,
            $HashAlgorithm,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

        $request.CertificateExtensions.Add(
            [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new(
                $request.PublicKey,
                $false)
        )

        $notBefore = [DateTimeOffset]::UtcNow.AddDays(-1)
        $notAfter = [DateTimeOffset]::UtcNow.AddDays(30)
        $request.CreateSelfSigned($notBefore, $notAfter)
    }
}
else {
    Function global:New-X509Certificate {
        [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Subject,

            [Parameter()]
            [System.Security.Cryptography.HashAlgorithmName]
            $HashAlgorithm = "SHA256"
        )

        $certParams = @{
            CertStoreLocation = 'Cert:\CurrentUser\My'
            HashAlgorithm = $HashAlgorithm.ToString()
            KeyAlgorithm = 'RSA'
            KeyLength = 4096
            Subject = $Subject
        }
        $cert = New-SelfSignedCertificate @certParams

        # We want to remove the private key file by exporting the cert as a PFX
        # and reimporting it without the persist key flag.
        $certBytes = $cert.Export(
            [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx)

        # New-SelfSignedCertificate stores the key in the store, we want to
        # remove the cert and key
        Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
        $certKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
        $certKey.Key.Delete()

        # EphemeralKeySet will ensure the key isn't persisted to the disk replicating
        # the PS 7 New-X509Certificate cmdlet
        [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $certBytes,
            '',
            [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]'EphemeralKeySet, Exportable')
    }
}
