# DPAPI-NG SecretManagement
## about_DpapiNGSecretManagement

# SHORT DESCRIPTION
This module can be used as a vault implementation for Microsoft's [SecretManagement](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/?view=ps-modules) module.
This guide will demonstrate how to register a DPAPI-NG vault and interact with it using the other `SecretManagement` cmdlets.
It is also possible to use the [ConvertTo-DpapiNGSecret](./ConvertTo-DpapiNGSecret.md) and [ConvertFrom-DpapiNGSecret](./ConvertFrom-DpapiNGSecret.md) cmdlets to encrypt and decrypt DPAPI-NG values manually without integration with a `SecretManagement` vault.

# LONG DESCRIPTION
The first step to using this with `SecretManagement` is to register a DPAPI-NG vault to interact with using [Register-SecretVault](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/register-secretvault?view=ps-modules).

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

This cmdlet will create a DPAPI-NG vault called `MyVault` that stores the secrets at `C:\path\to\vault_file`.
The vault file at `Path` will be automatically created when the first secret is stored.
It must be a the path to a file and the parent directory must already exist.
Once the vault is registered it can referenced by the `-VaultName MyVault` parameter on the other `SecretManagement` cmdlets.
It is possible to copy the vault file directory to other hosts as long as the secrets it contains is protected in a way that isn't tied to the same host.
The file format of the vault uses [LiteDB](https://github.com/mbdavid/LiteDB) but this is an implementation detail and can change in the future.

To set a DPAPI-NG secret the [Set-Secret](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/set-secret?view=ps-modules) cmdlet can be used:

```powershell
# Uses the default protection of 'LOCAL=user'
Set-Secret -Name MySecret -Vault MyVault -Secret password

# Uses a custom protection descriptor
$desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -CurrentSid
Set-Secret -Name MySecret -Vault MyVault -Secret password @desc

# Uses a custom protection descriptor as a manual string
# Also defines the Created metadata
Set-Secret -Name MySecret -Vault MyVault -Secret password -Metadata @{
    ProtectionDescriptor = "LOCAL=machine"
    Created = (Get-Date)
}
```

These cmdlets will both register the secret called `MySecret` which will encrypt the value `password` using DPAPI-NG.
The first example will protect it with the `LOCAL=user` protection descriptor ensuring on the current user on the current host can decrypt it.
The second example will protect it with the `SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User)` protection descriptor ensuring the current domain user can decrypt the secret on any domain joined host.
It is important in that scenario the `$desc` variable is splatted as this will automatically define it through the `-Metadata` parameter as needed.
The third example manually defines the protection descriptor as a string but also defines the `Created` metadata set to the current `DateTime`.
See [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md) and [Add-DpapniNGDescriptor](./Add-DpapiNGDescriptor.md) for how to build a protection descriptor for your needs.
Also see [DPAPI NG Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors) for more information on known protection descriptors.

To retrieve a DPAPI-NG secret the [Get-Secret](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/get-secret?view=ps-modules) cmdlet can be used:

```powershell
Get-Secret -Name MySecret -Vault MyVault
```

The vault will automatically decrypt the value if the user is authorized to do so.
If the secret has been protected in a way the user cannot decrypt then it will fail.

To remove a DPAPI-NG secret the [Remove-Secret](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/remove-secret?view=ps-modules) cmdlet can be used:

```powershell
Remove-Secret -Name MySecret -Vault MyVault
```

It is also possible to use [Get-SecretInfo](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/get-secretinfo?view=ps-modules) and [Set-SecretInfo](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/set-secretinfo?view=ps-modules) to get and set the metadata on a secret.
Metadata is extra data associated with the secret that is stored in plaintext.
The DPAPI-NG vault accepts free-form metadata keys allowing it to store whatever is needed in the scenario.
The only exception is the `ProtectionDescriptor` key and value which is reserved as the DPAPI-NG protection descriptor string used for the encrypted secret.
