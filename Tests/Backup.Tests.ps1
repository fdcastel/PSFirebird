Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'Backup' -ForEach $FirebirdVersions {
    BeforeAll {
        $script:FirebirdVersion = $_

        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabase = New-FirebirdDatabase -Database "$RootFolder/$FirebirdVersion-tests.fdb" -Environment $TestEnvironment

        $script:TestBackupFile = "$RootFolder/$FirebirdVersion-tests.fbk"

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }
        
    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Ensure the backup file does not exist before each test
        if (Test-Path $TestBackupFile) {
            Remove-Item -Path $TestBackupFile -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Backup a database with named parameters' {
        $TestBackupFile | Should -Not -Exist
        Backup-FirebirdDatabase -Database $TestDatabase -BackupFilePath $TestBackupFile -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Backup a database with positional parameters' {
        $TestBackupFile | Should -Not -Exist
        Backup-FirebirdDatabase $TestDatabase $TestBackupFile -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Backup a database with mixed parameters (1)' {
        $TestBackupFile | Should -Not -Exist
        Backup-FirebirdDatabase -Database $TestDatabase $TestBackupFile -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Backup a database with mixed parameters (2)' {
        $TestBackupFile | Should -Not -Exist
        Backup-FirebirdDatabase $TestDatabase -BackupFilePath $TestBackupFile -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Backup a database with pipeline input' {
        $TestBackupFile | Should -Not -Exist
        $TestDatabase | Backup-FirebirdDatabase -BackupFilePath $TestBackupFile -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Backup a database with no backup file specified' {
        $TestBackupFile | Should -Not -Exist
        $TestDatabase | Backup-FirebirdDatabase -Environment $TestEnvironment
        $TestBackupFile | Should -Exist
    }

    It 'Return a command-line string for a streamed backup' {
        $TestBackupFile | Should -Not -Exist
        $gbakArgs = Backup-FirebirdDatabase -Database $TestDatabase -AsCommandLine -Environment $script:TestEnvironment
        $TestBackupFile | Should -Not -Exist

        $gbakArgs[0] | Should -Be '-backup_database'
        $gbakArgs[-2] | Should -Be $TestDatabase.Path
        $gbakArgs[-1] | Should -Be 'stdout'
    }
}
