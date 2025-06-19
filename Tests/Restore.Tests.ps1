Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'Restore' -ForEach $FirebirdVersions {
    BeforeAll {
        $script:FirebirdVersion = $_

        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabase = New-FirebirdDatabase -DatabasePath "$RootFolder/$FirebirdVersion-tests.fdb" -Environment $TestEnvironment
        $script:TestBackupFile = "$RootFolder/$FirebirdVersion-tests.gbk"
        $script:TestDatabaseRestored = "$RootFolder/$FirebirdVersion-tests.restored.fdb"

        # Create a backup file to restore from
        Backup-FirebirdDatabase -DatabasePath $TestDatabase.DatabasePath -FilePath $TestBackupFile -Environment $TestEnvironment

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
        if (Test-Path $TestDatabaseRestored) {
            Remove-Item -Path $TestDatabaseRestored -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Restore a database with named parameters' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase -FilePath $TestBackupFile -DatabasePath $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with positional parameters' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase $TestBackupFile $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with mixed parameters (1)' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase -FilePath $TestBackupFile $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with mixed parameters (2)' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase $TestBackupFile -DatabasePath $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with pipeline input' {
        $TestDatabaseRestored | Should -Not -Exist
        $TestBackupFile | Restore-FirebirdDatabase -DatabasePath $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Return a command-line string for a streamed restore' {
        $TestDatabaseRestored | Should -Not -Exist
        $gbakArgs = Restore-FirebirdDatabase -AsCommandLine -DatabasePath $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Not -Exist
    
        $gbakArgs[0] | Should -Be '-create_database'
        $gbakArgs[-2] | Should -Be 'stdin'
        $gbakArgs[-1] | Should -Be $TestDatabaseRestored
    }
}
