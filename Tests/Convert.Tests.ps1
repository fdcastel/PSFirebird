Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'Convert' -Tag 'Integration' {
    BeforeAll {
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabase = New-FirebirdDatabase -Database "$RootFolder/$FirebirdVersion.fdb" -Environment $TestEnvironment
        $script:DatabaseRestored = "$RootFolder/$FirebirdVersion.restored.fdb"

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
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
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        # Cross-version test: convert from oldest (3.x) to newest (5.x)
        $script:SourceVersion = '3.0.12'
        $script:TargetVersion = $FirebirdVersion

        $script:SourceEnv = New-FirebirdEnvironment -Version $SourceVersion
        $script:TargetEnv = New-FirebirdEnvironment -Version $TargetVersion

        $script:SourceDb = New-FirebirdDatabase -Database "$RootFolder/source.fdb" -Environment $SourceEnv
        $script:NativeTargetDb = New-FirebirdDatabase -Database "$RootFolder/native-target.fdb" -Environment $TargetEnv

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
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
