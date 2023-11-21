---
external help file: SecretManagement.DpapiNG.Module.dll-Help.xml
Module Name: SecretManagement.DpapiNG
online version: https://www.github.com/jborean93/SecretManagement.DpapiNG/blob/main/docs/en-US/New-DpapiNGDescriptor.md
schema: 2.0.0
---

# New-DpapiNGDescriptor

## SYNOPSIS
Creates a DPAPI-NG protection descriptor used to encrypt data with DPAPI-NG.

## SYNTAX

```
New-DpapiNGDescriptor [<CommonParameters>]
```

## DESCRIPTION
This is used to create the DPAPI-NG protection descriptor string.
Use with [Add-DpapiNGDescriptor](./Add-DpapiNGDescriptor.md) to add descriptor elements to the protection string.

## EXAMPLES

### Example 1
```powershell
PS C:\> $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local User
PS C:\> Set-Secret -Vault MyVault -Name MySecret -Secret foo @desc
```

Creates a new protection descriptor for `LOCAL=user` which will protect the secret for the current user.
The descriptor is then used with `Set-Secret` to define how to protect the secret stored in the vault.
It is important to use the descriptor output using the splat syntax when provided ith `Set-Secret`.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### ProtectionDescriptor
The ProtectionDescriptor object that can be piped to Add-DpapiNGDescriptor (./Add-DpapiNGDescriptor.md).

## NOTES

## RELATED LINKS

[DPAPI NG Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors)
