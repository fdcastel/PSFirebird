Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'FirebirdDatabase' -ForEach $FirebirdVersions {
    BeforeAll {
        $script:FirebirdVersion = $_

        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabasePath = "$RootFolder/$FirebirdVersion-tests.fdb"

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Ensure the test database does not exist before each test
        if (Test-Path $TestDatabasePath) {
            Remove-Item -Path $TestDatabasePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Create database with default parameters' {
        $TestDatabasePath | Should -Not -Exist
        $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment
        $testDatabase.Environment | Should -Be $TestEnvironment
        $testDatabase.Path | Should -Be $TestDatabasePath
        $testDatabase.Path | Should -Exist
    }

    It 'Create database with context environment' {
        Use-FirebirdEnvironment -Environment $TestEnvironment {
            $TestDatabasePath | Should -Not -Exist
            $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath
            $testDatabase.Path | Should -Be $TestDatabasePath
            $testDatabase.Path | Should -Exist
        }
    }

    It 'Read database information' {
        $TestDatabasePath | Should -Not -Exist
        $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath -PageSize 4096 -Environment $TestEnvironment
        $TestDatabasePath | Should -Exist

        $info = Read-FirebirdDatabase -Database $testDatabase -Environment $TestEnvironment
        $info.Environment | Should -BeOfType FirebirdEnvironment
        $info.Database | Should -Be $TestDatabase
        $info['MON$PAGE_SIZE'] | Should -Be 4096
    }

    It 'Lock database' {
        $TestDatabasePath | Should -Not -Exist
        $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment
        $TestDatabasePath | Should -Exist

        $TestDatabase.IsLocked() | Should -BeFalse
        Lock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment
        $TestDatabase.IsLocked() | Should -BeTrue

        { Lock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment } | Should -Throw 'Database is already locked for backup.'
    }


    It 'Unlock database' {
        $TestDatabasePath | Should -Not -Exist
        $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment
        $TestDatabasePath | Should -Exist

        Lock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment
        $TestDatabase.IsLocked() | Should -BeTrue

        Unlock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment
        $TestDatabase.IsLocked() | Should -BeFalse

        { Unlock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment } | Should -Throw 'Database is not locked for backup.'
    }

    It 'Unlock fixes missing .delta file' {
        $TestDatabasePath | Should -Not -Exist
        $testDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment
        $TestDatabasePath | Should -Exist

        Lock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment
        $TestDatabase.IsLocked() | Should -BeTrue

        # Simulate missing .delta file by removing it
        $deltaFile = "$($TestDatabasePath).delta"
        Remove-Item -Path $deltaFile -Force

        Unlock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment
        $TestDatabase.IsLocked() | Should -BeFalse

        { Unlock-FirebirdDatabase -Database $TestDatabase -Environment $TestEnvironment } | Should -Throw 'Database is not locked for backup.'
    }
}
