. ([System.IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "*-DpapiNGDescriptor" {
    It "Builds descriptor string" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local User
        $actual.ToString() | Should -Be "LOCAL=user"
    }

    It "Builds metadata splat" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local User
        $enumerated = @($actual)
        $enumerated.Count | Should -Be 2
        $enumerated[0] | Should -Be "-Metadata"
        $enumerated[1] | Should -BeOfType ([Hashtable])
        $enumerated[1].Count | Should -Be 1
        $enumerated[1].ProtectionDescriptor | Should -Be "LOCAL=user"
    }

    It "Adds local descriptor" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local Machine
        $actual.ToString() | Should -Be "LOCAL=machine"
    }

    It "Adds sid descriptor" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Sid "S-1-5-19"
        $actual.ToString() | Should -Be "SID=S-1-5-19"
    }

    It "Adds sid from SID type" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Sid ([System.Security.Principal.SecurityIdentifier]::new("S-1-5-18"))
        $actual.ToString() | Should -Be "SID=S-1-5-18"
    }

    It "Adds sid from NTAccount type" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Sid ([System.Security.Principal.NTAccount]::new("SYSTEM"))
        $actual.ToString() | Should -Be "SID=S-1-5-18"
    }

    It "Adds sid from translated account string" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Sid SYSTEM
        $actual.ToString() | Should -Be "SID=S-1-5-18"
    }

    It "Fails to translate unknown account string for SID" {
        $err = {
            New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Sid invalid
        } | Should -Throw -PassThru
        [string]$err | Should -BeLike "Cannot bind parameter 'Sid'. Cannot convert value `"invalid`" to type `"StringOrAccount`". *"
    }

    It "Adds current sid descriptor" {
        $actual = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -CurrentSid
        $actual.ToString() | Should -Be "SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User)"
    }

    It "Combines multiple conditional" {
        $actual = New-DpapiNGDescriptor |
            Add-DpapiNGDescriptor -Local User |
            Add-DpapiNGDescriptor -Local Machine |
            Add-DpapiNGDescriptor -Sid "S-1-5-19" -Or
        $actual.ToString() | Should -Be "LOCAL=user AND LOCAL=machine OR SID=S-1-5-19"
    }
}
