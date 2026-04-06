Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Get-FirebirdVersion' -Tag 'Unit' {
    It 'Parses a Firebird 5.x Linux version string' {
        $result = Get-FirebirdVersion 'LI-V5.0.3.1683 Firebird 5.0'
        $result.Platform | Should -Be 'Linux'
        $result.Version | Should -Be '5.0.3'
        $result.Build | Should -Be 1683
        $result.ServerName | Should -Be 'Firebird 5.0'
    }

    It 'Parses a Firebird 4.x Windows version string' {
        $result = Get-FirebirdVersion 'WI-V4.0.5.3140 Firebird 4.0'
        $result.Platform | Should -Be 'Windows'
        $result.Version | Should -Be '4.0.5'
        $result.Build | Should -Be 3140
        $result.ServerName | Should -Be 'Firebird 4.0'
    }

    It 'Parses a Firebird 3.x version string' {
        $result = Get-FirebirdVersion 'LI-V3.0.12.33787 Firebird 3.0'
        $result.Platform | Should -Be 'Linux'
        $result.Version | Should -Be '3.0.12'
        $result.Build | Should -Be 33787
        $result.ServerName | Should -Be 'Firebird 3.0'
    }

    It 'Parses a version string without server name' {
        $result = Get-FirebirdVersion 'LI-V5.0.3.1683'
        $result.Platform | Should -Be 'Linux'
        $result.Version | Should -Be '5.0.3'
        $result.Build | Should -Be 1683
        $result.ServerName | Should -BeNullOrEmpty
    }

    It 'Returns [semver] type for Version property' {
        $result = Get-FirebirdVersion 'LI-V5.0.3.1683 Firebird 5.0'
        $result.Version | Should -BeOfType [semver]
    }

    It 'Accepts pipeline input' {
        $result = 'WI-V4.0.5.3140 Firebird 4.0' | Get-FirebirdVersion
        $result.Platform | Should -Be 'Windows'
        $result.Version | Should -Be '4.0.5'
    }

    It 'Throws on invalid version string' {
        { Get-FirebirdVersion 'not-a-version' } | Should -Throw '*Cannot parse Firebird version string*'
    }

    It 'Parses multiple strings from pipeline' {
        $results = @(
            'LI-V5.0.3.1683 Firebird 5.0'
            'WI-V4.0.5.3140 Firebird 4.0'
            'LI-V3.0.12.33787 Firebird 3.0'
        ) | Get-FirebirdVersion

        $results.Count | Should -Be 3
        $results[0].Version | Should -Be '5.0.3'
        $results[1].Version | Should -Be '4.0.5'
        $results[2].Version | Should -Be '3.0.12'
    }
}
