. ([System.IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "SecretManagement" {
    BeforeAll {
        $vault = 'DpapiNGTest'
        $vaultPath = "TestDrive:\dpapi-ng.vault"

        Register-SecretVault -Name $vault -ModuleName $CurrentModule.Path -VaultParameters @{
            Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($vaultPath)
        }
    }

    AfterAll {
        Unregister-SecretVault -Name $vault
        Remove-Item -Path $vaultPath -Force -ErrorAction SilentlyContinue
    }

    AfterEach {
        Get-SecretInfo -Vault $vault | Remove-Secret
    }

    It "Verifies a valid vault registration" {
        Test-SecretVault -Name $vault | Should -BeTrue
    }

    It "Sets a secret" {
        Set-Secret -Name MySecret -Secret value -Vault $vault

        $actual = Get-Secret -Name MySecret -Vault $vault -AsPlainText
        $actual | Should -Be value
    }

    It "Overwrites a secret" {
        Set-Secret -Name MySecret -Secret value -Vault $vault
        Set-Secret -Name MySecret -Secret value2 -Vault $vault

        $actual = Get-Secret -Name MySecret -Vault $vault -AsPlainText
        $actual | Should -Be value2
    }

    It "Fails to overwrite a secret with NoClobber" {
        Set-Secret -Name MySecret -Secret value -Vault $vault

        {
            Set-Secret -Name MySecret -Secret value2 -Vault $vault -NoClobber
        } | Should -Throw "A secret with name MySecret already exists in vault $vault."

        $actual = Get-Secret -Name MySecret -Vault $vault -AsPlainText
        $actual | Should -Be value
    }

    It "Sets a byte array secret" {
        $value = [byte[]]@(0, 1, 2, 3)

        Set-Secret -Name MySecret -Secret $value -Vault $vault
        $actual = Get-Secret -Name MySecret -Vault $vault
        , $actual | Should -BeOfType ([byte[]])
        $actual.Count | Should -Be 4
        $actual[0] | Should -Be ([byte]0)
        $actual[1] | Should -Be ([byte]1)
        $actual[2] | Should -Be ([byte]2)
        $actual[3] | Should -Be ([byte]3)
    }

    It "Sets a SecureString secret" {
        $value = ConvertTo-SecureString -AsPlainText -Force value

        Set-Secret -Name MySecret -Secret $value -Vault $vault

        $actual = Get-Secret -Name MySecret -Vault $vault
        $actual | Should -BeOfType ([securestring])
        [System.Net.NetworkCredential]::new("", $actual).Password | Should -Be value

        $actual = Get-Secret -Name MySecret -Vault $vault -AsPlainText
        $actual | Should -Be value
    }

    It "Sets a PSCredential secret" {
        $value = [PSCredential]::new("user", (ConvertTo-SecureString -AsPlainText -Force value))

        Set-Secret -Name MySecret -Secret $value -Vault $vault

        $actual = Get-Secret -Name MySecret -Vault $vault
        $actual | Should -BeOfType ([pscredential])
        $actual.UserName | Should -Be user
        $actual.GetNetworkCredential().Password | Should -Be value
    }

    It "Sets a Hashtable secret" {
        $value = @{
            foo = 'bar'
            value = 1
        }

        Set-Secret -Name MySecret -Secret $value -Vault $vault

        $actual = Get-Secret -Name MySecret -Vault $vault
        $actual | Should -BeOfType ([hashtable])
        $actual.Count | Should -Be 2
        $actual.foo | Should -BeOfType ([securestring])
        [System.Net.NetworkCredential]::new("", $actual.foo).Password | Should -Be bar
        $actual.value | Should -BeOfType ([int])
        $actual.value | Should -Be 1

        $actual = Get-Secret -Name MySecret -Vault $vault -AsPlainText
        $actual | Should -BeOfType ([hashtable])
        $actual.Count | Should -Be 2
        $actual.foo | Should -BeOfType ([string])
        $actual.foo | Should -Be bar
        $actual.value | Should -BeOfType ([int])
        $actual.value | Should -Be 1
    }

    It "Gets SecretInfo" {
        Set-Secret -Name MySecret1 -Secret value1 -Vault $vault
        Set-Secret -Name MySecret2 -Secret (ConvertTo-SecureString -AsPlainText -Force value2) -Vault $vault
        Set-Secret -Name MySecret3 -Secret ([byte[]]@(0, 1)) -Vault $vault
        Set-Secret -Name MySecret4 -Secret ([PSCredential]::new("user", (ConvertTo-SecureString -AsPlainText -Force value))) -Vault $vault
        Set-Secret -Name MySecret5 -Secret @{foo = 'bar' } -Vault $vault

        $secretInfo = Get-SecretInfo -Vault $vault
        $secretInfo.Count | Should -Be 5
        $secretInfo[0].Name | Should -Be MySecret1
        $secretInfo[0].Type | Should -Be String
        $secretInfo[0].VaultName | Should -Be $vault
        $secretInfo[0].Metadata.Count | Should -Be 1
        $secretInfo[0].Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"

        $secretInfo[1].Name | Should -Be MySecret2
        $secretInfo[1].Type | Should -Be SecureString
        $secretInfo[1].VaultName | Should -Be $vault
        $secretInfo[1].Metadata.Count | Should -Be 1
        $secretInfo[1].Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"

        $secretInfo[2].Name | Should -Be MySecret3
        $secretInfo[2].Type | Should -Be ByteArray
        $secretInfo[2].VaultName | Should -Be $vault
        $secretInfo[2].Metadata.Count | Should -Be 1
        $secretInfo[2].Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"

        $secretInfo[3].Name | Should -Be MySecret4
        $secretInfo[3].Type | Should -Be PSCredential
        $secretInfo[3].VaultName | Should -Be $vault
        $secretInfo[3].Metadata.Count | Should -Be 1
        $secretInfo[3].Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"

        $secretInfo[4].Name | Should -Be MySecret5
        $secretInfo[4].Type | Should -Be Hashtable
        $secretInfo[4].VaultName | Should -Be $vault
        $secretInfo[4].Metadata.Count | Should -Be 1
        $secretInfo[4].Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"
    }

    It "Gets SecretInfo with wildcard" {
        Set-Secret -Name MySecret1 -Secret value -Vault $vault
        Set-Secret -Name MySecret2 -Secret value -Vault $vault
        Set-Secret -Name Other -Secret value -Vault $vault

        $secretInfo = Get-SecretInfo -Vault $vault -Name MySec*
        $secretInfo.Count | Should -Be 2
        $secretInfo[0].Name | Should -Be MySecret1
        $secretInfo[1].Name | Should -Be MySecret2
    }

    It "Copies a secret across vaults" {
        $otherVault = 'OtherDpapiNG'
        $otherVaultPath = "TestDrive:\dpapi-ng-other.vault"

        Register-SecretVault -Name $otherVault -ModuleName $CurrentModule.Path -VaultParameters @{
            Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($otherVaultPath)
        }
        try {
            Set-Secret -Name MySecret -Secret foo -Vault $vault
            $si = Get-SecretInfo -Name MySecret
            Set-Secret -SecretInfo $si -Vault $otherVault

            $actual = Get-Secret -Name MySecret -AsPlainText
            $actual | Should -Be foo
        }
        finally {
            Unregister-SecretVault -Name $otherVault
            Remove-Item -Path $otherVaultPath -Force -ErrorAction SilentlyContinue
        }
    }

    It "Sets secret with metadata" {
        Set-Secret -Name MySecret -Secret value -Vault $vault -Metadata @{
            Created = ([DateTime]::new(1970, 1, 1))
        }

        Get-Secret -Name MySecret -Vault $vault -AsPlainText | Should -Be value

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 2
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"
        $actual.Metadata.Created | Should -BeOfType ([DateTime])
        $actual.Metadata.Created | Should -Be ([DateTime]::new(1970, 1, 1))
    }

    It "Adds extra metadata" {
        Set-Secret -Name MySecret -Secret value -Vault $vault -Metadata @{
            Created = ([DateTime]::new(1970, 1, 1))
            Other = 1
        }
        Set-SecretInfo -Name MySecret -Vault $vault -Metadata @{
            Other = 2
            Foo = 'bar'
        }

        Get-Secret -Name MySecret -Vault $vault -AsPlainText | Should -Be value

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 4
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"
        $actual.Metadata.Created | Should -BeOfType ([DateTime])
        $actual.Metadata.Created | Should -Be ([DateTime]::new(1970, 1, 1))
        $actual.Metadata.Other | Should -BeOfType ([int])
        $actual.Metadata.Other | Should -Be 2
        $actual.Metadata.Foo | Should -BeOfType ([string])
        $actual.Metadata.Foo | Should -Be bar
    }

    It "Sets secret with explicit ProtectionDescriptor" {
        $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local machine

        Set-Secret -Name MySecret -Secret value -Vault $vault @desc

        Get-Secret -Name MySecret -Vault $vault -AsPlainText | Should -Be value

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 1
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=machine"
    }

    It "Sets secret with explicit ProtectionDescriptor and extra metadata" {
        $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local machine

        Set-Secret -Name MySecret -Secret value -Vault $vault -Metadata @{
            ProtectionDescriptor = $desc.ToString()
            Other = 'foo'
        }

        Get-Secret -Name MySecret -Vault $vault -AsPlainText | Should -Be value

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 2
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=machine"
        $actual.Metadata.Other | Should -BeOfType ([string])
        $actual.Metadata.Other | Should -Be foo
    }

    It "Ignore changing ProtectionDescriptor with same value" {
        Set-Secret -Name MySecret -Secret value -Vault $vault
        Set-SecretInfo -Name MySecret -Vault $vault -Metadata @{
            Foo = 'bar'
            ProtectionDescriptor = 'LOCAL=user'
        }

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 2
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"
        $actual.Metadata.Foo | Should -BeOfType ([string])
        $actual.Metadata.Foo | Should -Be bar
    }

    It "Errors changing ProtectionDescriptor with different value" {
        Set-Secret -Name MySecret -Secret value -Vault $vault -Metadata @{
            Foo = 1
        }
        Set-SecretInfo -Name MySecret -Vault $vault -Metadata @{
            Foo = 2
            ProtectionDescriptor = 'LOCAL=machine'
        } -ErrorAction SilentlyContinue -ErrorVariable err

        $err.Count | Should -Be 1
        [string]$err | Should -Be "It is not possible to change the ProtectionDescriptor for an existing set. Use Set-SecretInfo to create a new secret instead."

        $actual = Get-SecretInfo -Name MySecret -Vault $vault
        $actual.Name | Should -Be MySecret
        $actual.Metadata.Count | Should -Be 2
        $actual.Metadata.ProtectionDescriptor | Should -Be "LOCAL=user"
        $actual.Metadata.Foo | Should -BeOfType ([int])
        $actual.Metadata.Foo | Should -Be 2
    }

    It "Errors while trying to set secret metadata on non-existent secret" {
        Set-SecretInfo -Name MySecret -Vault $vault -Metadata @{
            Foo = 2
        } -ErrorAction SilentlyContinue -ErrorVariable err

        $err.Count | Should -Be 1
        [string]$err | Should -Be "Failed to find SecretManagement.DpapiNG vault secret 'MySecret'. The secret must exist to set the metadata on. Use Set-Secret to create a secret with metadata instead."
    }

    It "Uses default vault path if none set" {
        $name1 = 'TestVault1'
        $name2 = 'TestVault2'
        $secretName = 'DpapiNGTestSecret'

        Register-SecretVault -ModuleName $CurrentModule.Path -Name $name1
        Register-SecretVault -ModuleName $CurrentModule.Path -Name $name2
        try {
            Test-SecretVault -Name $name1 | Should -BeTrue
            Test-SecretVault -Name $name2 | Should -BeTrue

            Set-Secret -Name $secretName -Secret value -Vault $name1

            Get-Secret -Name $secretName -AsPlainText -Vault $name1 | Should -Be value
            Get-Secret -Name $secretName -AsPlainText -Vault $name2 | Should -Be value
        }
        finally {
            Remove-Secret -Name $secretName -Vault $name1
            Unregister-SecretVault -Name $name1
            Unregister-SecretVault -Name $name2
        }
    }

    It "Fails if vault Path is not a FileSystem path" {
        $name = 'TestVault'
        Register-SecretVault -ModuleName $CurrentModule.Path -Name $name -VaultParameters @{
            Path = "HKLM:\SOFTWARE"
        }
        try {
            Test-SecretVault -Name $name -ErrorAction SilentlyContinue -ErrorVariable err
            $err.Count | Should -Be 1
            [string]$err | Should -Be "Invalid SecretManagement.DpapiNG vault registration: Path 'HKLM:\SOFTWARE' must be a local file path to the local LiteDB database. If the DB does not exist at the path a new vault will be created."
        }
        finally {
            Unregister-SecretVault -Name $name
        }
    }

    It "Fails if vault path parent does not exist" {
        $name = 'TestVault'
        Register-SecretVault -ModuleName $CurrentModule.Path -Name $name -VaultParameters @{
            Path = 'C:\missing\parent\vault'
        }
        try {
            Test-SecretVault -Name $name -ErrorAction SilentlyContinue -ErrorVariable err
            $err.Count | Should -Be 1
            [string]$err | Should -Be "Invalid SecretManagement.DpapiNG vault registration: Path 'C:\missing\parent\vault' must exist or the parent directory in the path must exist to create the new vault file."
        }
        finally {
            Unregister-SecretVault -Name $name
        }
    }

    It "Fails if vault path is a directory" {
        $name = 'TestVault'
        Register-SecretVault -ModuleName $CurrentModule.Path -Name $name -VaultParameters @{
            Path = "C:\Windows"
        }
        try {
            Test-SecretVault -Name $name -ErrorAction SilentlyContinue -ErrorVariable err
            $err.Count | Should -Be 1
            [string]$err | Should -Be "Invalid SecretManagement.DpapiNG vault registration: Path 'C:\Windows' must be the path to a file not a directory."
        }
        finally {
            Unregister-SecretVault -Name $name
        }
    }
}
