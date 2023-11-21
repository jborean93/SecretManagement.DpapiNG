---
external help file: SecretManagement.DpapiNG.Module.dll-Help.xml
Module Name: SecretManagement.DpapiNG
online version: https://www.github.com/jborean93/SecretManagement.DpapiNG/blob/main/docs/en-US/ConvertTo-DpapiNGSecret.md
schema: 2.0.0
---

# ConvertTo-DpapiNGSecret

## SYNOPSIS
Encrypts data as a DPAPI-NG secret.

## SYNTAX

### Local (Default)
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]> [-Encoding <Encoding>]
 [-Local <String>] [<CommonParameters>]
```

### ProtectionDescriptor
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]>
 [[-ProtectionDescriptor] <StringOrProtectionDescriptor>] [-Encoding <Encoding>] [<CommonParameters>]
```

### Sid
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]> [-Encoding <Encoding>]
 -Sid <StringOrAccount> [<CommonParameters>]
```

### SidCurrent
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]> [-Encoding <Encoding>] [-CurrentSid]
 [<CommonParameters>]
```

### Certificate
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]> [-Encoding <Encoding>]
 -Certificate <X509Certificate2> [<CommonParameters>]
```

### CertificateThumbprint
```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]> [-Encoding <Encoding>]
 -CertificateThumbprint <String> [<CommonParameters>]
```

## DESCRIPTION
Encrypts the input data into a base64 encoded string.
The encrypted data is protected using the protection descriptor specified.
Use [ConvertFrom-DpapiNGSecret](./ConvertFrom-DpapiNGSecret.md) to decrypt the secret data back into a usable object.
By default the secret will be protected with the `LOCAL=user` protection descriptor which only allows the current user on the current host the ability to decrypt the secret.

See [about_DpapiNGProtectionDescriptor](./about_DpapiNGProtectionDescriptor.md) for more details.

## EXAMPLES

### Example 1 - Encrypt a string for the current domain user
```powershell
PS C:\> ConvertTo-DpapiNGSecret secret -CurrentSid
```

Encrypts the string `secret` as a DPAPI-NG blob protected by the current domain user.
The same user can decrypt the encrypted blob on any host in the domain.

### Exapmle 2 - Encrypt bytes for the local machine
```powershell
PS C:\> $bytes = [System.IO.File]::ReadAllBytes($path)
# Example using pipeline
PS C:\> , $bytes | ConvertTo-DpapiNGSecret -Local Machine
# Exapmle using parameters
PS C:\> ConvertTo-DpapiNGSecret -InputObject $bytes -Local Machine
```

Encrypts the provided bytes as a DPAPI-NG blob protected by the current local machine.
The same machine can decrypt the encrypted blob.

### Example 3 - Encrypt a secret for a specific domain group
```powershell
PS C:\> $da = [System.Security.Principal.NTAccount]'DOMAIN\Domain Admins'
PS C:\> ConvertTo-DpapiNGSecret secret -Sid $da
```

Encrypts the provided string as a DPAPI-NG blob protected by membership to the `Domain Admins` group.
Any other member of that group will be able to decrypt that secret.

### Example 4 - Encrypt a secret using a complex protection descriptor
```powershell
PS C:\> $da = [System.Security.Principal.NTAccount]'DOMAIN\Domain Admins'
PS C:\> $desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -CurrentSid |
    Add-DpapiNGDescriptor -Sid $da -Or
PS C:\> ConvertTo-DpapiNGSecret secret -ProtectionDescriptor $desc
```

Builds a more complex protection descriptor that allows a member of the `Domain Admins` group or the current domain user the ability to decrypt the DPAPI-NG secret.
It is also possible to provide a string to `-ProtectionDescriptor` if crafting it manually.

## PARAMETERS

### -Certificate
The `X509Certificate2` to use when encrypting the data.
The decryptor needs to have the associated private key of the certificate used to decrypt the value.
This method will set the protection descriptor `CERTIFICATE=CertBlob:$certBase64String`.

```yaml
Type: X509Certificate2
Parameter Sets: Certificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateThumbprint
The thumbprint for a certificate stored inside `Cert:\CurrentUser\My` to use for encryption.
Only the public key needs to be present to encrypt the value but the decryption process requires the associated private key to be present.
This method will set the protection descriptor `CERTIFICATE=HashID:$CertificateThumbprint`.

```yaml
Type: String
Parameter Sets: CertificateThumbprint
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CurrentSid
Protects the secret with the current domain user's identity.
The encrypted secret can be decrypted by this user on any other host in the domain.
This is the equivalent of doing `-ProtectionDescriptor "SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User)"`.

Using a `SID` protection descriptor requires the host to be joined to a domain with a forest level of 2012 or newer.

```yaml
Type: SwitchParameter
Parameter Sets: SidCurrent
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding
The encoding used to encode the string into bytes before it is encrypted.
The encoding default to `UTF-8` if not specified.

This accepts a `System.Text.Encoding` type but also a string or int representing the encoding from `[System.Text.Encoding]::GetEncoding(...)`.
Some common encoding values are:

+ `UTF8` - UTF-8 but without a Byte Order Mark (BOM)

+ `ASCII` - ASCII (bytes 0-127)

+ `ANSI` - The ANSI encoding commonly used in legacy Windows encoding

+ `OEM` - The value of `[System.Console]::OutputEncoding`

+ `Unicode` - UTF-16-LE

+ `UTF8Bom` - UTF-8 but with a BOM

+ `UTF8NoBom` - Same as Utf8

The `ANSI` encoding typically refers to the legacy Windows encoding used in older PowerShell versions.
If creating a script that should be used across the various PowerShell versions, it is highly recommended to use an encoding with a BOM like `UTF8Bom` or `Unicode`.

```yaml
Type: Encoding
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
The data to encrypt.
The value can be on of the following types

+ `String`

+ `SecureString`

+ `byte[]`

When a `String` or `SecureString` is used, the `-Encoding` argument is used to convert the value to bytes before it is encrypted.

```yaml
Type: StringSecureStringOrByteArray[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Local
Protects the secret using the `LOCAL=machine`, `LOCAL=user`, or `LOCAL=logon` protection descriptor.
The `User` value protects the secret to just this user on the current host and is the default value.
The `Machine` value protects the secret to the current computer.
The `Logon` value protects the secret to just this user's logon session.
This is slightly different to `User` in that the same user logged on through another session will be unable to decrypt the secret.

```yaml
Type: String
Parameter Sets: Local
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProtectionDescriptor
The protection descriptor string to use to protect the value.
The [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md) and [Add-DpapiNGDescriptor](./Add-DpapiNGDescriptor.md) can be used to build the protection descriptor value.
A string can also be provided here as the protection descriptor using the rules defined by DPAPI-NG.

```yaml
Type: StringOrProtectionDescriptor
Parameter Sets: ProtectionDescriptor
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sid
Allows only the domain user or domain group specified by this SID to be able to decrypt the DPAPI-NG secret.
If a group SID is specified, any user who is a member of that group can decrypt the secret it applies to.
The value can either by a SecurityIdentifier string in the format `S-1-...` or as a [System.Security.Principal.NTAccount](https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.ntaccount?view=net-8.0) object which will automatically be translated to a SID.

Using a `SID` protection descriptor requires the host to be joined to a domain with a forest level of 2012 or newer.

```yaml
Type: StringOrAccount
Parameter Sets: Sid
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### StringSecureStringOrByteArray
The `-InputObject` to encrypt.

## OUTPUTS

### System.String
The encrypted DPAPI-NG blob as a base64 encoded string.

## NOTES

## RELATED LINKS

[DPAPI NG Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors)
[about_DpapiNGProtectionDescriptor](./about_DpapiNGProtectionDescriptor.md)
