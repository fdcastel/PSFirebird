Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Get-FirebirdReleaseUrl' {
    InModuleScope 'PSFirebird' {
        BeforeEach {
            Mock Invoke-RestMethod {
                Get-Content "$PSScriptRoot/assets/github-releases.json" -Raw | ConvertFrom-Json
            }
        }

        It 'Returns releases URL for Firebird 5.x' {
            Get-FirebirdReleaseUrl -Version '5.0.2' -RuntimeIdentifier 'win-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.2/Firebird-5.0.2.1613-0-windows-x64.zip'

            Get-FirebirdReleaseUrl -Version '5.0.1' -RuntimeIdentifier 'win-x86' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.1/Firebird-5.0.1.1469-0-windows-x86.zip'

            Get-FirebirdReleaseUrl -Version '5.0.0' -RuntimeIdentifier 'linux-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0/Firebird-5.0.0.1306-0-linux-x64.tar.gz'

            Get-FirebirdReleaseUrl -Version '5.0.0' -RuntimeIdentifier 'linux-arm64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0/Firebird-5.0.0.1306-0-linux-arm64.tar.gz'
        }

        It 'Returns releases URL for Firebird 4.x' {
            Get-FirebirdReleaseUrl -Version '4.0.5' -RuntimeIdentifier 'win-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.5/Firebird-4.0.5.3140-0-x64.zip'

            Get-FirebirdReleaseUrl -Version '4.0.4' -RuntimeIdentifier 'win-x86' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.4/Firebird-4.0.4.3010-0-Win32.zip'

            Get-FirebirdReleaseUrl -Version '4.0.3' -RuntimeIdentifier 'linux-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.3/Firebird-4.0.3.2975-0.amd64.tar.gz'

            Get-FirebirdReleaseUrl -Version '4.0.2' -RuntimeIdentifier 'linux-arm64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v4.0.2/Firebird-4.0.2.2816-0.arm64.tar.gz'
        }

        It 'Returns releases URL for Firebird 3.x' {
            Get-FirebirdReleaseUrl -Version '3.0.12' -RuntimeIdentifier 'win-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.12/Firebird-3.0.12.33787-0-x64.zip'

            Get-FirebirdReleaseUrl -Version '3.0.11' -RuntimeIdentifier 'win-x86' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.11/Firebird-3.0.11.33703-0_Win32.zip'

            Get-FirebirdReleaseUrl -Version '3.0.10' -RuntimeIdentifier 'linux-x64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.10/Firebird-3.0.10.33601-0.amd64.tar.gz'

            Get-FirebirdReleaseUrl -Version '3.0.9' -RuntimeIdentifier 'linux-arm64' |
                Should -Be 'https://github.com/FirebirdSQL/firebird/releases/download/v3.0.9/Firebird-3.0.9.33560-0.arm64.tar.gz'
        }
    }
}
