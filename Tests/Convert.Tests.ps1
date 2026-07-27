Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'Convert' -Tag 'Integration' {
    BeforeAll {
        $script:Fixture = New-TestFixture -DatabaseName "$FirebirdVersion.fdb"
        $script:RootFolder = $Fixture.RootFolder
        $script:TestEnvironment = $Fixture.Environment
        $script:TestDatabase = $Fixture.Database
        $script:DatabaseRestored = "$RootFolder/$FirebirdVersion.restored.fdb"
    }

    AfterAll {
        Remove-TestFixture -Fixture $Fixture
    }

    BeforeEach {
        if (Test-Path $DatabaseRestored) {
            Remove-Item -Path $DatabaseRestored -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Convert a database from same version' {
        $DatabaseRestored | Should -Not -Exist
        Convert-FirebirdDatabase -SourceDatabase $TestDatabase `
                                 -SourceEnvironment $TestEnvironment `
                                 -TargetDatabase $DatabaseRestored `
                                 -TargetEnvironment $TestEnvironment
        $DatabaseRestored | Should -Exist
    }
}

Describe 'Convert Cross-Version' -Tag 'CrossVersion' {
    BeforeAll {
        # The target environment and credentials come from the shared fixture; this suite
        # additionally installs an older source environment to convert from.
        $script:Fixture = New-TestFixture -NoDatabase
        $script:RootFolder = $Fixture.RootFolder

        # Cross-version test: convert from oldest (3.x) to newest
        $script:SourceVersion = '3.0.13'

        # FB3 has no win-arm64 binary (available only from FB6+).
        # When the target env uses win-arm64, fall back to win-x64 (x64 emulation) for the FB3 source.
        $sourceExtraParams = if ($FirebirdExtraParams.ContainsKey('RuntimeIdentifier') -and
                                 $FirebirdExtraParams.RuntimeIdentifier -eq 'win-arm64') {
            @{ RuntimeIdentifier = 'win-x64' }
        } else {
            $FirebirdExtraParams
        }

        $script:SourceEnv = New-FirebirdEnvironment -Version $SourceVersion @sourceExtraParams
        $script:TargetEnv = $Fixture.Environment

        $script:SourceDb = New-FirebirdDatabase -Database "$RootFolder/source.fdb" -Environment $SourceEnv
        $script:NativeTargetDb = New-FirebirdDatabase -Database "$RootFolder/native-target.fdb" -Environment $TargetEnv
    }

    AfterAll {
        Remove-TestFixture -Fixture $Fixture
    }

    It 'Cross-version conversion produces correct ODS' {
        if ($SourceEnv.Version.Major -eq $TargetEnv.Version.Major) {
            Set-ItResult -Skipped -Because 'Source and target are the same major version'
            return
        }

        # Get the expected ODS version from a database created natively with the target environment
        $expectedODS = (Get-FirebirdDatabase -Path $NativeTargetDb.Path -Environment $TargetEnv).ODSVersion

        $convertedPath = "$RootFolder/converted.fdb"
        $convertedPath | Should -Not -Exist

        Convert-FirebirdDatabase -SourceDatabase $SourceDb `
                                 -SourceEnvironment $SourceEnv `
                                 -TargetDatabase $convertedPath `
                                 -TargetEnvironment $TargetEnv

        $convertedPath | Should -Exist

        # Verify the converted database has the ODS version of the target environment
        $convertedODS = (Get-FirebirdDatabase -Path $convertedPath -Environment $TargetEnv).ODSVersion
        $convertedODS.Major | Should -Be $expectedODS.Major -Because "converted database should have ODS major version from target environment"
    }
}
