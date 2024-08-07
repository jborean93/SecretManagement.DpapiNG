---
external help file: SecretManagement.DpapiNG.Module.dll-Help.xml
Module Name: SecretManagement.DpapiNG
online version: https://www.github.com/jborean93/SecretManagement.DpapiNG/blob/main/docs/en-US/Add-DpapiNGDescriptor.md
schema: 2.0.0
---

# Add-DpapiNGDescriptor

## SYNOPSIS
Adds a new protection descriptor clause.

## SYNTAX

### Local (Default)
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] [-Local <String>] [<CommonParameters>]
```

### Sid
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] -Sid <StringOrAccount> [<CommonParameters>]
```

### SidCurrent
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] [-CurrentSid] [<CommonParameters>]
```

### Certificate
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] -Certificate <X509Certificate2>
 [<CommonParameters>]
```

### CertificateThumbprint
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] -CertificateThumbprint <String>
 [<CommonParameters>]
```

### WebCredential
```
Add-DpapiNGDescriptor -InputObject <ProtectionDescriptor> [-Or] -WebCredential <String> [<CommonParameters>]
```

## DESCRIPTION
Adds a new protection descriptor clause to an existing protection descriptor created by [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md).
Each new clause will be added with an `AND` unless `-Or` is specified.
The protection descriptor is used to descibe what entities are allowed to decrypt the secret it protects.
The following descriptor types are supported:

+ `LOCAL`

+ `SID`

+ `CERTIFICATE`

+ `WEBCREDENTIALS`

See [about_DpapiNGProtectionDescriptor](./about_DpapiNGProtectionDescriptor.md) for more details.

## EXAMPLES

### Example 1 - Adds the Local user clause
```powershell
PS C:\> $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local User
PS C:\> Set-Secret -Vault MyVault -Name MySecret -Secret foo @desc
```

Creates a new protection descriptor for `LOCAL=user` which will protect the secret for the current user.
The descriptor is then used with `Set-Secret` to define how to protect the secret stored in the vault.
It is important to use the descriptor output using the splat syntax when provided ith `Set-Secret`.

### Example 2 - Adds the SID specified
```powershell
PS C:\> $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -CurrentSid
PS C:\> ConvertTo-DpapiNGSecret secret -ProtectionDescriptor $desc
```

Creates a DPAPI-NG secret that is protected by the current user.
This secret can be decrypted on any host in the domain running under the same user.

### Example 3 - Adds multiple SIDs
```powershell
PS C:\> $domainAdmins = 'DOMAIN\Domain Admins'
PS C:\> $desc = New-DpapiNGDescriptor |
    Add-DpapiNGDescriptor -CurrentSid |
    Add-DpapiNGDescriptor -Sid $domainAdmins
PS C:\> ConvertTo-DpapiNGSecret secret -ProtectionDescriptor $desc
```

Creates a DPAPI-NG secret that is protected by the current user when a `Domain Admins` member.
The string value for `-Sid` here is automatically converted to the `System.Security.Principal.NTAccount` object and translated to the `SecurityIdentifier` string.

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
Adds the clause `SID=$UserSid` where `$UserSid` represents the current user's SecurityIdentifier.
A secret protected by this value can be decrypted by this user on any machine in the domain.

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

### -InputObject
The protection descriptor object generated by [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md).

```yaml
Type: ProtectionDescriptor
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Local
Adds the `LOCAL` descriptor clause to either `User`, `Machine`, `Logon`.
The `User` value protects the secret to just this user on the current host.
The `Machine` value protects the secret to the current computer.
The `Logon` value protects the secret to just this user's logon session.
This is slightly different to `User` in that the same user logged on through another session will be unable to decrypt the secret.

```yaml
Type: String
Parameter Sets: Local
Aliases:
Accepted values: User, Machine

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Or
Adds the new descriptor clause with an `OR` rather than an `AND`.
How this is treated by DPAPI-NG depends on the existing clauses that have already been added.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sid
Adds the `SID` descriptor clause to the SecurityIdentifier specified.
The SecurityIdentifier can be the SID of a domain user or group.
If a group SID is specified, any user who is a member of that group can decrypt the secret it applies to.
The value can either by a SecurityIdentifier string in the format `S-1-...`, NTAccount string that will be translated to a `SecurityIdentifier` string, or as a [System.Security.Principal.NTAccount](https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.ntaccount?view=net-8.0) object which will automatically be translated to a SID.

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

### -WebCredential
The credential manager to protect the secret with.
The string value is in the format `username,resource`, for example a web credential for `dpapi-ng.com` with the user `MyUser` would be `-WebCredential 'MyUser,dpapi-ng.com'`.

```yaml
Type: String
Parameter Sets: WebCredential
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

### ProtectionDescriptor
The ProtectionDescriptor object created by New-DpapiNGDescriptor (./New-DpapiNGDescriptor.md).

## OUTPUTS

### ProtectionDescriptor
The modified ProtectionDescriptor object with the new clause.

## NOTES

## RELATED LINKS

[DPAPI NG Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors)
[about_DpapiNGProtectionDescriptor](./about_DpapiNGProtectionDescriptor.md)
