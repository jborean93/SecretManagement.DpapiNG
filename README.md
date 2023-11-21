# SecretManagement.DpapiNG

[![Test workflow](https://github.com/jborean93/SecretManagement.DpapiNG/workflows/Test%20SecretManagement.DpapiNG/badge.svg)](https://github.com/jborean93/SecretManagement.DpapiNG/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/jborean93/SecretManagement.DpapiNG/branch/main/graph/badge.svg?token=b51IOhpLfQ)](https://codecov.io/gh/jborean93/SecretManagement.DpapiNG)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/SecretManagement.DpapiNG.svg)](https://www.powershellgallery.com/packages/SecretManagement.DpapiNG)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jborean93/SecretManagement.DpapiNG/blob/main/LICENSE)

A PowerShell module that can be used to encrypt and decrypt data using [DPAPI NG](https://learn.microsoft.com/en-us/windows/win32/seccng/cng-dpapi) also known as `CNG DPAPI`.
The module also implements a `SecretManagement` extension that can be used for interacting with a DPAPI-NG vault registered with the [SecretManagement](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/?view=ps-modules) module.

See [SecretManagement.DpapiNG index](docs/en-US/SecretManagement.DpapiNG.md) for more details.

## Requirements

These cmdlets have the following requirements

* PowerShell v5.1 or newer

Currently this module only works on Windows, it cannot be used on Linux or macOS.

## Examples
To encrypt a string with DPAPI-NG use the following:

```powershell
# Encrypts the secret so only the current user on the current host can decrypt.
ConvertTo-DpapiNGSecret MySecret

# Encrypts the secret so only the current domain user on any host can decrypt.
ConvertTo-DpapiNGSecret MySecret -CurrentSid

# Encrypts the secret so only Domain Admins on any host can decrypt.
$da = [System.Security.Principal.NTAccount]'DOMAIN\Domain Admins'
ConvertTo-DpapiNGSecret MySecret -Sid $da
```

To decrypt the DPAPI-NG blob back:

```powershell
# Decrypts back as a SecureString
ConvertFrom-DpapiNGSecret $secret

# Decrypts back as a String
ConvertFrom-DpapiNGSecret $secret -AsString
```

See [ConvertTo-DpapiNGSecret](./docs/en-US/ConvertTo-DpapiNGSecret.md) and [ConvertFrom-DpapiNGSecret](./docs/en-US/ConvertFrom-DpapiNGSecret.md) for more details.

To register a DPAPI-NG vault for use with `SecretManagement`:

```powershell
$vaultParams = @{
    Name = 'MyVault'
    ModuleName = 'SecretManagement.DpapiNG'
    VaultParameters = @{
        Path = 'C:\path\to\vault_file'
    }
}
Register-SecretVault @vaultParams
```

The vault `MyVault` can now be used with [Set-Secret](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/set-secret?view=ps-modules) and [Get-Secret](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/get-secret?view=ps-modules) to get and set secrets using DPAPI-NG.

```powershell
# Uses the default protection of 'LOCAL=user'
Set-Secret -Name MySecret -Vault MyVault -Secret password

# Uses a custom protection descriptor to protect for the current user
$desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -CurrentSid
Set-Secret -Name MySecret -Vault MyVault -Secret password @desc

# Uses a custom protection descriptor as a manual string
Set-Secret -Name MySecret -Vault MyVault -Secret password -Metadata @{
    ProtectionDescriptor = "SID=..."
}

# Get the secret value
Get-Secret -Name MySecret -Vault MyVault
```

See [about_DpapiNGSecretManagement](./docs/en-US/about_DpapiNGSecretManagement.md) for more information on how to use this module with `SecretManagement`.

## Installing

The easiest way to install this module is through [PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).

You can install this module by running;

```powershell
# Install for only the current user
Install-Module -Name SecretManagement.DpapiNG, Microsoft.PowerShell.SecretManagement -Scope CurrentUser

# Install for all users
Install-Module -Name SecretManagement.DpapiNG, Microsoft.PowerShell.SecretManagement -Scope AllUsers
```

If the `SecretManagement` implementation is not needed, the `Microsoft.PowerShell.SecretManagement` package can be omitted during the install.

## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the changes.
To build this module run `.\build.ps1 -Task Build` in PowerShell.
To test a build run `.\build.ps1 -Task Test` in PowerShell.
This script will ensure all dependencies are installed before running the test suite.
