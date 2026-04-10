Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'GitHub releases' -Tag 'Unit' {
    InModuleScope 'PSFirebird' {
        BeforeEach {
            Mock Invoke-RestMethod {
                Get-Content "$PSScriptRoot/assets/github-releases.json" -Raw | ConvertFrom-Json
            }
        }

        It 'Returns release info for Firebird 6.x' {
            $result = Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'win-x64'
            $result.Url | Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v6.0.0/Firebird-6.0.0.1900-0-windows-x64.zip'
            $result.FileName | Should -Be 'Firebird-6.0.0.1900-0-windows-x64.zip'
            $result.Version | Should -Be '6.0.0'
            $result.Sha256 | Should -Be 'a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6'

            (Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'win-x86').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v6.0.0/Firebird-6.0.0.1900-0-windows-x86.zip'

            (Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'linux-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v6.0.0/Firebird-6.0.0.1900-0-linux-x64.tar.gz'

            (Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'linux-arm64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v6.0.0/Firebird-6.0.0.1900-0-linux-arm64.tar.gz'

            (Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'win-arm64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v6.0.0/Firebird-6.0.0.1900-0-windows-arm64.zip'
        }

        It 'Returns release info for Firebird 5.x' {
            $result = Get-FirebirdReleaseUrl -Version '5.0.2' -RuntimeIdentifier 'win-x64'
            $result.Url | Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.2/Firebird-5.0.2.1613-0-windows-x64.zip'
            $result.FileName | Should -Be 'Firebird-5.0.2.1613-0-windows-x64.zip'
            $result.Version | Should -Be '5.0.2'
            $result.Sha256 | Should -Be 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4'

            (Get-FirebirdReleaseUrl -Version '5.0.1' -RuntimeIdentifier 'win-x86').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.1/Firebird-5.0.1.1469-0-windows-x86.zip'

            (Get-FirebirdReleaseUrl -Version '5.0.0' -RuntimeIdentifier 'linux-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0/Firebird-5.0.0.1306-0-linux-x64.tar.gz'

            (Get-FirebirdReleaseUrl -Version '5.0.0' -RuntimeIdentifier 'linux-arm64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0/Firebird-5.0.0.1306-0-linux-arm64.tar.gz'

            { Get-FirebirdReleaseUrl -Version '5.0.2' -RuntimeIdentifier 'win-arm64' } |
                Should -Throw "*not supported for Firebird 5.x*"
        }

        It 'Returns release info for Firebird 4.x' {
            (Get-FirebirdReleaseUrl -Version '4.0.5' -RuntimeIdentifier 'win-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.5/Firebird-4.0.5.3140-0-x64.zip'

            (Get-FirebirdReleaseUrl -Version '4.0.4' -RuntimeIdentifier 'win-x86').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.4/Firebird-4.0.4.3010-0-Win32.zip'

            (Get-FirebirdReleaseUrl -Version '4.0.3' -RuntimeIdentifier 'linux-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.3/Firebird-4.0.3.2975-0.amd64.tar.gz'

            (Get-FirebirdReleaseUrl -Version '4.0.2' -RuntimeIdentifier 'linux-arm64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.2/Firebird-4.0.2.2816-0.arm64.tar.gz'
        }

        It 'Returns release info for Firebird 3.x' {
            (Get-FirebirdReleaseUrl -Version '3.0.12' -RuntimeIdentifier 'win-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.12/Firebird-3.0.12.33787-0-x64.zip'

            (Get-FirebirdReleaseUrl -Version '3.0.11' -RuntimeIdentifier 'win-x86').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.11/Firebird-3.0.11.33703-0_Win32.zip'

            (Get-FirebirdReleaseUrl -Version '3.0.10' -RuntimeIdentifier 'linux-x64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.10/Firebird-3.0.10.33601-0.amd64.tar.gz'

            (Get-FirebirdReleaseUrl -Version '3.0.9' -RuntimeIdentifier 'linux-arm64').Url |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.9/Firebird-3.0.9.33560-0.arm64.tar.gz'
        }
        It 'Returns Sha256 when digest field is available (v6.0.0)' {
            $result = Get-FirebirdReleaseUrl -Version '6.0.0' -RuntimeIdentifier 'linux-x64'
            $result.Sha256 | Should -Be 'd6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6f6a6b6c6d6e6'
        }

        It 'Returns Sha256 when digest field is available (v5.0.2)' {
            $result = Get-FirebirdReleaseUrl -Version '5.0.2' -RuntimeIdentifier 'linux-x64'
            $result.Sha256 | Should -Be 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'
        }

        It 'Returns null Sha256 when digest field is not available (v4.0.5)' {
            $result = Get-FirebirdReleaseUrl -Version '4.0.5' -RuntimeIdentifier 'linux-x64'
            $result.Sha256 | Should -BeNullOrEmpty
        }
    }

    Context 'Find-FirebirdRelease (public)' {
        BeforeEach {
            Mock Invoke-RestMethod {
                Get-Content "$PSScriptRoot/assets/github-releases.json" -Raw | ConvertFrom-Json
            } -ModuleName 'PSFirebird'
        }

        It 'Returns a PSCustomObject with Version, FileName, Url, and Sha256' {
            $result = Find-FirebirdRelease -Version '5.0.2' -RuntimeIdentifier 'linux-x64'
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Be '5.0.2'
            $result.FileName | Should -Be 'Firebird-5.0.2.1613-0-linux-x64.tar.gz'
            $result.Url | Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.2/Firebird-5.0.2.1613-0-linux-x64.tar.gz'
            $result.Sha256 | Should -Be 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'
        }

        It 'Works for all major versions' {
            $r6 = Find-FirebirdRelease -Version '6.0.0' -RuntimeIdentifier 'linux-x64'
            $r6.FileName | Should -BeLike 'Firebird-6.0.0*linux-x64*'

            $r5 = Find-FirebirdRelease -Version '5.0.0' -RuntimeIdentifier 'linux-arm64'
            $r5.FileName | Should -BeLike 'Firebird-5.0.0*linux-arm64*'

            $r4 = Find-FirebirdRelease -Version '4.0.5' -RuntimeIdentifier 'linux-x64'
            $r4.FileName | Should -BeLike 'Firebird-4.0.5*'

            $r3 = Find-FirebirdRelease -Version '3.0.12' -RuntimeIdentifier 'win-x64'
            $r3.FileName | Should -BeLike 'Firebird-3.0.12*'
        }

        It 'Throws for unsupported versions' {
            { Find-FirebirdRelease -Version '2.5.9' } | Should -Throw '*minimal supported version*'
        }
    }
}
