Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'Convert' {
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
                Database = New-FirebirdDatabase -DatabasePath "$RootFolder/$firebirdVersion.fdb" -Environment $fbEnv
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
            Convert-FirebirdDatabase -SourceDatabase $e.Database.DatabasePath `
                                     -SourceEnvironment $e.Environment `
                                     -TargetDatabase $e.DatabaseRestored `
                                     -TargetEnvironment $e.Environment
            $e.DatabaseRestored | Should -Exist
        }
    }
}
