. ([System.IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Convert*-DpapiNGSecret" {
    It "Converts a string secret" {
        $secret = ConvertTo-DpapiNGSecret foo

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a string secret as pipeline input" {
        $secret = 'foo' | ConvertTo-DpapiNGSecret

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a SecureString secret" {
        $value = ConvertTo-SecureString -AsPlainText -Force foo
        $secret = ConvertTo-DpapiNGSecret $value

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a SecureString secret as pipeline input" {
        $value = ConvertTo-SecureString -AsPlainText -Force foo
        $secret = $value | ConvertTo-DpapiNGSecret

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a byte[] secret" {
        $value = [System.Text.Encoding]::UTF8.GetBytes("foo")
        $secret = ConvertTo-DpapiNGSecret $value

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a byte[] secret as pipeline input" {
        $value = [System.Text.Encoding]::UTF8.GetBytes("foo")
        $secret = , $value | ConvertTo-DpapiNGSecret

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts a byte array as list secret" {
        $value = [System.Collections.Generic.List[byte]][System.Text.Encoding]::UTF8.GetBytes("foo")
        $secret = ConvertTo-DpapiNGSecret $value

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts other objects to a string for secret" {
        $obj = [PSCustomObject]@{}
        $obj | Add-Member -Name ToString -MemberType ScriptMethod -Value { "foo" } -Force

        $secret = ConvertTo-DpapiNGSecret $obj

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Decrypts to a SecureString" {
        $secret = ConvertTo-DpapiNGSecret foo

        $actual = $secret | ConvertFrom-DpapiNGSecret
        $actual | Should -BeOfType ([securestring])
        [System.Net.NetworkCredential]::new("", $actual).Password | Should -Be foo
    }

    It "Decrypts to a Byte Array" {
        $secret = ConvertTo-DpapiNGSecret foo

        $actual = $secret | ConvertFrom-DpapiNGSecret -AsByteArray
        , $actual | Should -BeOfType ([byte[]])
        $actual.Count | Should -Be 3
        $actual[0] | Should -Be ([byte]102)
        $actual[1] | Should -Be ([byte]111)
        $actual[2] | Should -Be ([byte]111)
    }

    It "Fails to convert with invalid descriptor" {
        {
            ConvertTo-DpapiNGSecret foo -ProtectionDescriptor 'INVALID=value'
        } | Should -Throw
    }

    It "Fails to decrypt data" -Skip:$SIDUnvailable {
        $secret = ConvertTo-DpapiNGSecret foo -Sid "S-1-5-19"

        $actual = $secret | ConvertFrom-DpapiNGSecret -ErrorAction SilentlyContinue -ErrorVariable err
        $actual | Should -BeNullOrEmpty
        $err.Count | Should -Be 1
        [string]$err | Should -BeLike "Failed to decrypt data: The specified data could not be decrypted* (0x8009002C)"
    }

    It "Converts string with encoding <Encoding>" -TestCases @(
        @{ Encoding = 'utf8'; Expected = "636166C3A9" }
        @{ Encoding = 65001; Expected = "636166C3A9" }
        @{ Encoding = [System.Text.Encoding]::UTF8; Expected = "636166C3A9" }
        @{ Encoding = 'windows-1252'; Expected = "636166E9" }
        @{ Encoding = 'Unicode'; Expected = "630061006600E900" }
    ) {
        param ($Encoding, $Expected)

        # café
        $value = "caf$([char]0xE9)"

        $secret = ConvertTo-DpapiNGSecret $value -Encoding $Encoding

        $secret | ConvertFrom-DpapiNGSecret -AsString -Encoding $Encoding | Should -Be $value

        $actualBytes = (($secret | ConvertFrom-DpapiNGSecret -AsByteArray) | ForEach-Object ToString X2) -join ""
        $actualBytes | Should -Be $Expected
    }

    It "Converts with protection descriptor string" {
        $secret = 'foo' | ConvertTo-DpapiNGSecret -ProtectionDescriptor "LOCAL=user"

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts with protection descriptor object" {
        $desc = New-DpapiNGDescriptor | Add-DpapiNGDescriptor -Local User
        $secret = 'foo' | ConvertTo-DpapiNGSecret -ProtectionDescriptor $desc

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts with the current sid" -Skip:$SIDUnvailable {
        $secret = ConvertTo-DpapiNGSecret foo -CurrentSid

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Converts with the explicit sid <Sid>" -Skip:$SIDUnvailable -TestCases @(
        @{ Sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User }
        @{ Sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
        @{ Sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Translate([System.Security.Principal.NTAccount]) }
    ) {
        param ($Sid)

        $secret = ConvertTo-DpapiNGSecret foo -Sid $Sid

        $secret | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
    }

    It "Completes <Cmdlet> -Encoding parameter" -TestCases @(
        @{ Cmdlet = 'ConvertFrom-DpapiNGSecret' }
        @{ Cmdlet = 'ConvertTo-DpapiNGSecret' }
    ) {
        param ($Cmdlet)

        $actual = Complete "$Cmdlet -Encoding "
        $actual.Count | Should -Be 7

        # The first should be UTF8
        $actual[0].CompletionText | Should -Be 'UTF8'

        $actual | ForEach-Object {
            $_.CompletionText | Should -BeIn @(
                "UTF8"
                "ASCII"
                "ANSI"
                "OEM"
                "Unicode"
                "UTF8Bom"
                "UTF8NoBom"
            )
        }
    }

    It "Completes <Cmdlet> -Encoding parameter with partial match" -TestCases @(
        @{ Cmdlet = 'ConvertFrom-DpapiNGSecret' }
        @{ Cmdlet = 'ConvertTo-DpapiNGSecret' }
    ) {
        param ($Cmdlet)

        $actual = Complete "$Cmdlet -Encoding A"
        $actual.Count | Should -Be 2

        $actual | ForEach-Object {
            $_.CompletionText | Should -BeIn @(
                "ASCII"
                "ANSI"
            )
        }

        $actual = Complete "$Cmdlet -Encoding A*"
        $actual.Count | Should -Be 2

        $actual | ForEach-Object {
            $_.CompletionText | Should -BeIn @(
                "ASCII"
                "ANSI"
            )
        }
    }
}
