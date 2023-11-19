$ErrorActionPreference = 'Stop'

Get-SecretVault | Unregister-SecretVault

Register-SecretVault -Name DpapiStore -ModuleName ./output/SecretManagement.DpapiNG -VaultParameters @{ None = "ReallyNeeded" } -Verbose
Get-Secret -Name abc -Vault DpapiStore
