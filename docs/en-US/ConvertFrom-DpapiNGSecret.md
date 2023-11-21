---
external help file: SecretManagement.DpapiNG.Module.dll-Help.xml
Module Name: SecretManagement.DpapiNG
online version: https://www.github.com/jborean93/SecretManagement.DpapiNG/blob/main/docs/en-US/ConvertFrom-DpapiNGSecret.md
schema: 2.0.0
---

# ConvertFrom-DpapiNGSecret

## SYNOPSIS
Decrypts a DPAPI-NG secret.

## SYNTAX

### AsSecureString (Default)
```
ConvertFrom-DpapiNGSecret [-InputObject] <String[]> [-AsSecureString] [-Encoding <Encoding>]
 [<CommonParameters>]
```

### AsByteArray
```
ConvertFrom-DpapiNGSecret [-InputObject] <String[]> [-AsByteArray] [<CommonParameters>]
```

### AsString
```
ConvertFrom-DpapiNGSecret [-InputObject] <String[]> [-AsString] [-Encoding <Encoding>] [<CommonParameters>]
```

## DESCRIPTION
Decrypts a DPAPI-NG secret created by [ConvertTo-DpapiNGSecret](./ConvertTo-DpapiNGSecret.md).
The input data is a base64 encoded string of the raw DPAPI-NG blob.
The output object is dependent on the `-As*` switch specified and defaults as a `SecureString`.

## EXAMPLES

### Example 1 - Decrypts a DPAPI-NG secret
```powershell
PS C:\> $secret = ConvertTo-DpapiNGSecret secret
PS C:\> $secret | ConvertFrom-DpapiNGSecret
```

Decrypts a DPAPI-NG encoded secret into a `SecureString`.

### Example 2 - Decrypts a DPAPI-NG secret to bytes
```powershell
PS C:\> $secret | ConvertFrom-DpapiNGSecret -AsByteArray
```

Decrypts a DPAPI-NG encoded secret into a `byte[]`.

### Example 3 - Decrypts a DPAPI-NG secret to a string with specific encoding
```powershell
PS C:\> $secret | ConvertFrom-DpapiNGSecret -AsString -Encoding windows-1252
```

Decrypts a DPAPI-NG encoded secret into a `string` using the `windows-1252` encoding.

## PARAMETERS

### -AsByteArray
Outputs the decrypted value as a `byte[]` object.

```yaml
Type: SwitchParameter
Parameter Sets: AsByteArray
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsSecureString
Outputs the decrypted value as a `SecureString`.
This is the default output if no switch is specified.

```yaml
Type: SwitchParameter
Parameter Sets: AsSecureString
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsString
Outputs the decrypted value as a `String`.

```yaml
Type: SwitchParameter
Parameter Sets: AsString
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding
The encoding to use when decoding the bytes to a `String` or `SecureString`.
Defaults to UTF8 if no encoding is specified.

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
Parameter Sets: AsSecureString, AsString
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
The base64 encoded DPAPI-NG blob to decrypt.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Byte[]
The decrypted value as a `byte[]` when `-AsByteArray` is specified.

### System.Security.SecureString
The decrypted value as a `SecureString` when no `-As*` switch or `-AsSecureString` is specified.

### System.String
The decrypted value as a `String` when `-AsString` is specified.

## NOTES

## RELATED LINKS
