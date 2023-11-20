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

```
ConvertTo-DpapiNGSecret [-InputObject] <StringSecureStringOrByteArray[]>
 [[-ProtectionDescriptor] <StringOrProtectionDescriptor>] [-Encoding <Encoding>] [<CommonParameters>]
```

## DESCRIPTION
Encrypts the input data into a base64 encoded string.
The encrypted data is protected using the protection descriptor specified.
Use [ConvertFrom-DpapiNGSecret](./ConvertFrom-DpapiNGSecret.md) to decrypt the secret data back into a usable object.
The [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md) and [Add-DpapiNGDescriptor](./Add-DpapiNGDescriptor.md) to build the protection descriptor used to protect the secret.

## EXAMPLES

### Example 1 - Encrypt a string for the current domain user
```powershell
PS C:\> $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -CurrentSid
PS C:\> ConvertTo-DpapiNGSecret secret -ProtectionDescriptor $desc
```

Encrypts the string `secret` as a DPAPI-NG blob protected by the current domain user.
The same user can decrypt the encrypted blob on any host in the domain.

### Exapmle 2 - Encrypt bytes for the local machine
```powershell
PS C:\> $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local Machine
PS C:\> $bytes = [System.IO.File]::ReadAllBytes($path)
# Example using pipeline
PS C:\> @(,$bytes) | ConvertTo-DpapiNGSecret -ProtectionDescriptor $desc
# Exapmle using parameters
PS C:\> ConvertTo-DpapiNGSecret -InputObject $bytes -ProtectionDescriptor $desc
```

Encrypts the provided bytes as a DPAPI-NG blob protected by the current local machine.
The same machine can decrypt the encrypted blob.

## PARAMETERS

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

### -ProtectionDescriptor
The protection descriptor string to use to protect the value.
The [New-DpapiNGDescriptor](./New-DpapiNGDescriptor.md) and [Add-DpapiNGDescriptor](./Add-DpapiNGDescriptor.md) to build the protection descriptor value.

```yaml
Type: StringOrProtectionDescriptor
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
