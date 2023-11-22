# DPAPI-NG SecretManagement
## about_DpapiNGProtectionDescriptor

# SHORT DESCRIPTION
DPAPI-NG uses a protection descriptor that defines how the data is encrypted and what is allowed to decrypt the data.
This guide will go through the known protection descriptor types and how they are used in this module.

# LONG DESCRIPTION
Microsoft documents the protection descriptor string format under [CNG Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors).
While it is possible to define a custom protection descriptor string there are a few types that are predefined through some helper parameters:

|Type|Options|Description|
|-|-|-|
|`LOCAL`|`Logon`, `Machine`, `User`|Protects the data to the logon session, computer, or user|
|`SID`|`S-*`|Protects the data to the domain user or group specified|
|`CERTIFICATE`|`HashID:$certThumbprint`, `CertBlobc:$certB64String`|Protects the data using the certificate provided.|
|`WEBCREDENTIALS`|`$username,$resource`|Protects the data with the password of a web credential stored in credential manager.|

There is also the `SDDL` type but it is not exposed through a helper parameter in this module.
The `SDDL` format is the more advanced format of the `SID` type but the way it is defined is a lot more complex.
It is still possible to use this type, or any future types, with `-ProtectionDescriptor "SDDL=..."` through a manual string.

# LOCAL
The `LOCAL` protection descriptor can be used to encrypt a secret that only the current logon session, computer/machine, or user can decrypt.
A `LOCAL=logon` protection description is designed to encrypt a secret just for the current logon session.
A logon session is a Windows logon session like an interactive logon or through secondary logon tools like `runas.exe`.
Once a logon session is closed any secret scoped to that session can no longer be decrypted.
A `LOCAL=user` protection descriptor can be used to protect data that only that user on that host can decrypt.
This is similar to how a serialized `SecureString` can only be decrypted by the current user on the current host.
A `LOCAL=machine` protection descriptor can be used to protect data that can be decrypted by any user on the current host.
The `LOCAL` type is specified through the `-Local Logon|Machine|User` parameter:

```powershell
ConvertTo-DpapiNGSecret foo -Local Logon
ConvertTo-DpapiNGSecret foo -Local Machine
ConvertTo-DpapiNGSecret foo -Local User
```

By default if no protection descriptor is specified the `-Local User` descriptor will be used.

# SID
The `SID` protection descriptor is used to encrypt data that is scoped to a specific domain user or domain groups.
To use the `SID` type, the host must be joined to a domain with a forest level of 2012 or newer.
Attempting to use the `SID` type on a non-domain host or one joined to an older forest will fail.
The `SID` value is just the SecurityIdentifier string `S-1-...` that represents the domain user or the domain group a user is a member of that is allowed to decrypt the value.
The `SID` type is specified through the `-Sid S-1-...` or `-CurrentSid` parameters.
The `-CurrentSid` switch is shorthand for `-Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().Sid)`.
It is also possible to specify an `NTAccount` object as the value and the cmdlet will internally convert the account to a SecurityIdentifier.

```powershell
ConvertTo-DpapiNGSecret foo -Sid S-1-5-21-1786775912-3884064449-72196952-1104
ConvertTo-DpapiNGSecret foo -CurrentSid

$da = [System.Security.Principal.NTAccount]'DOMAIN\Domain Admins'
ConvertTo-DpapiNGSecret foo -Sid $da
```

It is possible to use an `OR` clause with `SID` types when specifying the accounts that can decrypt a value.
Unlike `AND`, an `OR` condition means that an account only needs to have one of the SecurityIdentifiers specified.

```powershell
$desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -Sid S-1-5-10 |
    Add-DpapiNGDescriptor -Sid S-1-5-11 -Or

ConvertTo-DpapiNGSecret foo -ProtectionDescriptor $desc
```

In the above example a domain user only needs to have the `S-1-5-10` or `S-1-5-11` SecurityIdentifiers to be able to decrypt the data.

While undocumented the `SDDL` type is tied to the `SID` type with `SID` being a user friendly representation of how `SDDL` works.

# CERTIFICATE
The `CERTIFICATE` protection descriptor can be used to protect a secret using a locally stored certificate.
Anyone who has access to the certificate public key can encrypt a value while only users with the private key can decrypt it.
The `-CertificateThumbprint` or `-Certificate` parameters can be used to specify this protection type.

```powershell
ConvertTo-DpapiNGSecret foo -CertificateThumbprint F952FF847B99811990DB27B04ABDB318A28ACD6E

$cert = Import-PfxCertificate -FilePath cert.pfx
ConvertTo-DpapiNGSecret foo -Certificate $cert
```

If using `-CertificateThumbprint` the certificate referenced by the thumbprint must exist in the `Cert:\CurrentUser\My` certificate store.
If using `-Certificate` the certificate does not need to be in any store to encrypt the data.
To decrypt the data, the private key referenced by the certificate must be accessible by the user.
Typically this means the certificate is stored in `Cert:\CurrentUser\My` with a referenced private key.

# WEBCREDENTIALS
The `WEBCREDENTIALS` protection descriptor can be used to protect a secret using a saved Web Credential in the Credential Manager.
Web Credentials are typically used by WinRT/Store applications where a credential is scoped specifically for the application that created them.
They are set to roam across devices using the same Microsoft Account profile making the secret portable outside of a domain environment.
One downside is that for normal Win32 applications that are not WinRT/Store apps, these credentials are visible to that user and not just when running the app that created it.

The `-WebCredential` parameter can be used to specify this protection type.

```powershell
ConvertTo-DpapiNGSecret foo -WebCredential 'username,resource'
```

While typically Web Credentials are created by specific WinRT/Store applications it is possible to do so globally for user.
The following code can be used in Windows PowerShell 5.1 to manage Web Credentials using the WinRT [PasswordVault Class](https://learn.microsoft.com/en-us/uwp/api/windows.security.credentials.passwordvault?view=winrt-22621):

```powershell
$vault = [Windows.Security.Credentials.PasswordVault, Windows.Security.Credentials, ContentType = WindowsRuntime]::new()

# Retrieves all Web Credentials
$vault.RetrieveAll() | Select-Object -Property UserName, Resource

# Retrieves all Web Credentials for a resource
$vault.FindAllByResource("resource")

# Retrieves all Web Credentials for a username
$vault.FindAllByUserName("username")

# Adds a new Web Credential
$vault.Add([Windows.Security.Credentials.PasswordCredential, Windows.Security.Credentials, ContentType = WindowsRuntime]::new(
    "resource",
    "username",
    "password"
))

# Removes a specific Web Credential
$vault.Remove($vault.Retrieve("resource", "username"))
```

Please note that this will only work in Windows PowerShell (`powershell.exe` 5.1) and not PowerShell (`pwsh.exe` 7+) which lacks the required WinRT components.
Also doing so will create a web credential that is not scoped to a specific application but rather the user as Windows PowerShell is a Win32 application.

# AND Conditions
Using the [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md) and [Add-DpapiNGDescriptor](./Add-DpapiNGDescriptor.md) cmdlets it is possible to create a descriptor with multiple clauses.
It is possible to use with with the `SID` type, other types might be possible but the behaviour with `AND` on other types is unknown and undocumented.

When using conditions put together with `AND`, the decryptor must meet each condition to be able to decrypt the value.

```powershell
$dbAdmins = [System.Security.Principal.NTAccount]'DOMAIN\DBA Admins'
$backupAdmins = [System.Security.Principal.NTAccount]'DOMAIN\Backup Admins'
$desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -Sid $dbAdmins |
    Add-DpapiNGDescriptor -Sid $backupAdmins

ConvertTo-DpapiNGSecret foo -ProtectionDescriptor $desc
```

In the above example, only domain users who are members of the `DBA Admins` and `Backup Admins` group will be able to decrypt the value.
