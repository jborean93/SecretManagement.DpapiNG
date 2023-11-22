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

    Context "Certificate tests" {
        BeforeAll {
            $cert = New-X509Certificate -Subject DPAPING-Test

            $certWithPublicBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            $certWithPrivateBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx)
            $certWithPublicOnly = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certWithPublicBytes)
        }

        AfterAll {
            $cert.Dispose()
            $certWithPublicOnly.Dispose()
        }

        It "Fails with cert thumbprint not in user store" {
            $actual = ConvertTo-DpapiNGSecret foo -CertificateThumbprint $cert.Thumbprint -ErrorAction SilentlyContinue -ErrorVariable err
            $actual | Should -BeNullOrEmpty
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to encrypt data: * (*)"
        }

        It "Protects with CertificateThumbprint" {
            $certWithPrivate = $myStore = $null
            try {
                $certWithPrivate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                    $certWithPrivateBytes,
                    "",
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                $myStore = Get-Item Cert:\CurrentUser\My
                $myStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                $myStore.Add($certWithPrivate)

                $actual = ConvertTo-DpapiNGSecret foo -CertificateThumbprint $certWithPublicOnly.Thumbprint

                ConvertFrom-DpapiNGSecret $actual -AsString | Should -Be foo
            }
            finally {
                if ($myStore) {
                    $myStore.Remove($certWithPrivate)
                    $myStore.Dispose()
                }
                if ($certWithPrivate) {
                    $key = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey(
                        $certWithPrivate)
                    $key.Key.Delete()
                    $certWithPrivate.Dispose()
                }
            }
        }

        It "Protects with Certificate object" {
            $actual = ConvertTo-DpapiNGSecret foo -Certificate $certWithPublicOnly

            $certWithPrivate = $myStore = $null
            try {
                $certWithPrivate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                    $certWithPrivateBytes,
                    "",
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)

                $myStore = Get-Item Cert:\CurrentUser\My
                $myStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                $myStore.Add($certWithPrivate)

                ConvertFrom-DpapiNGSecret $actual -AsString | Should -Be foo
            }
            finally {
                if ($myStore) {
                    $myStore.Remove($certWithPrivate)
                    $myStore.Dispose()
                }
                if ($certWithPrivate) {
                    $key = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey(
                        $certWithPrivate)
                    $key.Key.Delete()
                    $certWithPrivate.Dispose()
                }
            }
        }

        It "Fails to decrypt Certificate without stored key" {
            $actual = ConvertTo-DpapiNGSecret foo -Certificate $certWithPublicOnly

            $actual = ConvertFrom-DpapiNGSecret $actual -AsString -ErrorAction SilentlyContinue -ErrorVariable err
            $actual | Should -BeNullOrEmpty
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to decrypt data: * (*)"
        }

        It "Fails to decrypt Certificate with only public certificate" {
            $actual = ConvertTo-DpapiNGSecret foo -Certificate $certWithPublicOnly

            $myStore = $null
            try {
                $myStore = Get-Item Cert:\CurrentUser\My
                $myStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                $myStore.Add($certWithPublicOnly)

                $actual = ConvertFrom-DpapiNGSecret $actual -AsString -ErrorAction SilentlyContinue -ErrorVariable err
                $actual | Should -BeNullOrEmpty
                $err.Count | Should -Be 1
                [string]$err | Should -BeLike "Failed to decrypt data: * (*)"
            }
            finally {
                if ($myStore) {
                    $myStore.Remove($certWithPublicOnly)
                    $myStore.Dispose()
                }
            }
        }
    }

    Context "WebCredential test" {
        BeforeAll {
            $resource = 'SecretManagement.DpapiNG.Test'
            $username = 'DpapiNG-User'

            # WinRT only works in Windows PowerShell, use an implicit
            # removing session for Pwsh.
            $session = $null
            if ($IsCoreCLR) {
                $session = New-PSSession -UseWindowsPowerShell

                Invoke-Command -Session $session -Scriptblock ${function:New-WebCredential} -ArgumentList $resource, $username
            }
            else {
                New-WebCredential -Resource $resource -UserName $username
            }
        }

        AfterAll {
            if ($session) {
                Invoke-Command -Session $session -Scriptblock ${function:Remove-WebCredential} -ArgumentList $resource, $username

                $session | Remove-PSSession
            }
            else {
                Remove-WebCredential -Resource $resource -UserName $username
            }
        }

        It "Creates web credential secret" {
            $actual = ConvertTo-DpapiNGSecret foo -WebCredential "$username,$resource"

            $actual | ConvertFrom-DpapiNGSecret -AsString | Should -Be foo
        }
    }
}
