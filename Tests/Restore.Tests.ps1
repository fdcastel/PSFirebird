Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'Restore' -Tag 'Integration' {
    BeforeAll {
        $script:Fixture = New-TestFixture
        $script:RootFolder = $Fixture.RootFolder
        $script:TestEnvironment = $Fixture.Environment
        $script:TestDatabase = $Fixture.Database

        $script:TestBackupFile = "$RootFolder/$FirebirdVersion-tests.fbk"
        $script:TestDatabaseRestored = "$RootFolder/$FirebirdVersion-tests.restored.fdb"

        # Create a backup file to restore from
        Backup-FirebirdDatabase -Database $TestDatabase -BackupFilePath $TestBackupFile -Environment $TestEnvironment
    }

    AfterAll {
        Remove-TestFixture -Fixture $Fixture
    }

    BeforeEach {
        # Ensure the restored database does not exist before each test
        if (Test-Path $TestDatabaseRestored) {
            Remove-Item -Path $TestDatabaseRestored -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Restore a database with named parameters' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase -BackupFilePath $TestBackupFile -Database $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with positional parameters' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase $TestBackupFile $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with mixed parameters (1)' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase -BackupFilePath $TestBackupFile $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with mixed parameters (2)' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase $TestBackupFile -Database $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restore a database with pipeline input' {
        $TestDatabaseRestored | Should -Not -Exist
        $TestBackupFile | Restore-FirebirdDatabase -Database $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist
    }

    It 'Restored database has same ODS version as source' {
        $TestDatabaseRestored | Should -Not -Exist
        Restore-FirebirdDatabase -BackupFilePath $TestBackupFile -Database $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Exist

        $sourceODS = (Get-FirebirdDatabase -Path $TestDatabase.Path -Environment $TestEnvironment).ODSVersion
        $restoredODS = (Get-FirebirdDatabase -Path $TestDatabaseRestored -Environment $TestEnvironment).ODSVersion
        $restoredODS.Major | Should -Be $sourceODS.Major -Because 'restored database should have same ODS major version as source'
    }

    It 'Return a command-line string for a streamed restore' {
        $TestDatabaseRestored | Should -Not -Exist
        $gbakArgs = Restore-FirebirdDatabase -AsCommandLine -Database $TestDatabaseRestored -Environment $TestEnvironment
        $TestDatabaseRestored | Should -Not -Exist
    
        $gbakArgs[0] | Should -Be '-create_database'
        $gbakArgs[-2] | Should -Be 'stdin'
        $gbakArgs[-1] | Should -Be $TestDatabaseRestored
    }

    It 'Throws when restoring from a non-existent backup file' {
        { Restore-FirebirdDatabase -BackupFilePath "$RootFolder/nonexistent.fbk" -Database "$RootFolder/fail.fdb" -Environment $TestEnvironment } | Should -Throw
    }
}
