Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'Convert' -Tag 'Integration' {
    BeforeAll {
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        # Create one test environment for each Firebird version
        $script:testEnvironments = @{}
        $FirebirdVersions | ForEach-Object {
            $firebirdVersion = $_

            $fbEnv = New-FirebirdEnvironment -Version $firebirdVersion
            $e = @{
                Environment = $fbEnv
                Database = New-FirebirdDatabase -Database "$RootFolder/$firebirdVersion.fdb" -Environment $fbEnv
                DatabaseRestored = "$RootFolder/$firebirdVersion.restored.fdb"
            }

            $testEnvironments.Add($fbEnv.Version.Major, $e)
        }

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Ensure the restored database does not exist before each test
        $testEnvironments.Keys | ForEach-Object {
            $e = $testEnvironments[$_]
            if (Test-Path $e.DatabaseRestored) {
                Remove-Item -Path $e.DatabaseRestored -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Convert a database from same version' {
        $testEnvironments.Keys | ForEach-Object {
            $e = $testEnvironments[$_]
            $e.DatabaseRestored | Should -Not -Exist
            Convert-FirebirdDatabase -SourceDatabase $e.Database `
                                     -SourceEnvironment $e.Environment `
                                     -TargetDatabase $e.DatabaseRestored `
                                     -TargetEnvironment $e.Environment
            $e.DatabaseRestored | Should -Exist
        }
    }

    It 'Convert a database across versions produces correct ODS' {
        # Convert from the lowest to the highest Firebird version
        $sortedKeys = $testEnvironments.Keys | Sort-Object
        $sourceKey = $sortedKeys | Select-Object -First 1
        $targetKey = $sortedKeys | Select-Object -Last 1

        if ($sourceKey -eq $targetKey) {
            Set-ItResult -Skipped -Because 'Only one Firebird version available'
            return
        }

        $source = $testEnvironments[$sourceKey]
        $target = $testEnvironments[$targetKey]

        # Get the expected ODS version from a database created natively with the target environment
        $expectedODS = (Get-FirebirdDatabase -Path $target.Database.Path -Environment $target.Environment).ODSVersion

        $convertedPath = "$RootFolder/converted-$($sourceKey)-to-$($targetKey).fdb"
        $convertedPath | Should -Not -Exist

        Convert-FirebirdDatabase -SourceDatabase $source.Database `
                                 -SourceEnvironment $source.Environment `
                                 -TargetDatabase $convertedPath `
                                 -TargetEnvironment $target.Environment

        $convertedPath | Should -Exist

        # Verify the converted database has the ODS version of the target environment
        $convertedODS = (Get-FirebirdDatabase -Path $convertedPath -Environment $target.Environment).ODSVersion
        $convertedODS.Major | Should -Be $expectedODS.Major -Because "converted database should have ODS major version from target environment (FB$($targetKey))"
    }
}
