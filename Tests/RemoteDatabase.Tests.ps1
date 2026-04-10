Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'Remote Database Operations' -Tag 'Integration' {
    BeforeAll {
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment @FirebirdEnvParams @FirebirdExtraParams

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'

        # Create a test database and set up SYSDBA for TCP auth
        $script:LocalDatabase = New-FirebirdDatabase -Database "$RootFolder/remote-tests.fdb" -Environment $TestEnvironment
        "CREATE OR ALTER USER SYSDBA PASSWORD 'masterkey';" | Invoke-FirebirdIsql -Database $LocalDatabase -Environment $TestEnvironment

        # Start a Firebird server on a high port
        $script:Port = 50100 + $TestEnvironment.Version.Major
        $script:TestInstance = Start-FirebirdInstance -Environment $TestEnvironment -Port $Port
        Start-Sleep -Seconds 1

        # Build remote connection string
        $script:RemoteConnectionString = "localhost/$($Port):$($LocalDatabase.Path)"
        $script:RemoteDatabase = [FirebirdDatabase]::new($RemoteConnectionString)
    }

    AfterAll {
        if ($TestInstance -and -not $TestInstance.Process.HasExited) {
            $TestInstance.Process | Stop-Process -ErrorAction SilentlyContinue
        }
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Invoke-FirebirdIsql over TCP' {
        It 'Executes SQL over a remote connection' {
            $result = 'SELECT 1 AS VAL FROM RDB$DATABASE;' | 
                Invoke-FirebirdIsql -Database $RemoteDatabase -Environment $TestEnvironment
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Confirms protocol is TCP' {
            $result = 'SET LIST ON; SELECT mon$remote_protocol FROM mon$attachments WHERE mon$attachment_id = CURRENT_CONNECTION;' | 
                Invoke-FirebirdIsql -Database $RemoteDatabase -Environment $TestEnvironment
            $result | Where-Object { $_ -match 'MON\$REMOTE_PROTOCOL' } |
                Should -Match 'MON\$REMOTE_PROTOCOL\s+TCP.*'
        }
    }

    Context 'Read-FirebirdDatabase over TCP' {
        It 'Reads database info over a remote connection' {
            $info = Read-FirebirdDatabase -Database $RemoteDatabase -Environment $TestEnvironment
            $info | Should -Not -BeNull
            $info['MON$PAGE_SIZE'] | Should -BeGreaterThan 0
        }
    }

    Context 'Get-FirebirdDatabase over TCP' {
        It 'Returns database info with PageSize and ODSVersion' {
            $db = Get-FirebirdDatabase -Database $RemoteDatabase -Environment $TestEnvironment
            $db | Should -Not -BeNull
            $db.PageSize | Should -BeGreaterThan 0
            $db.ODSVersion | Should -Not -BeNull
        }

        It 'Preserves remote connection properties' {
            $db = Get-FirebirdDatabase -Database $RemoteDatabase -Environment $TestEnvironment
            $db.Host | Should -Be 'localhost'
            $db.Port | Should -Be "$Port"
            $db.Path | Should -Be $LocalDatabase.Path
        }
    }

    Context 'Test-FirebirdDatabase over TCP' {
        It 'Returns true for valid remote database' {
            Test-FirebirdDatabase -Database $RemoteDatabase -Environment $TestEnvironment | Should -BeTrue
        }

        It 'Returns false for non-existent remote database' {
            $fakeRemote = [FirebirdDatabase]::new("localhost/$($Port):$RootFolder/nonexistent.fdb")
            Test-FirebirdDatabase -Database $fakeRemote -Environment $TestEnvironment | Should -BeFalse
        }
    }

    Context 'Get-FirebirdDatabaseStatistics over TCP' {
        BeforeAll {
            # Create a table so statistics have something to report
            "CREATE TABLE REMOTE_TEST (ID INTEGER NOT NULL, CONSTRAINT PK_REMOTE_TEST PRIMARY KEY (ID));" |
                Invoke-FirebirdIsql -Database $RemoteDatabase -Environment $TestEnvironment
        }

        It 'Returns statistics with tables and indices' {
            $result = Get-FirebirdDatabaseStatistics -Database $RemoteDatabase -Environment $TestEnvironment
            $result | Should -Not -BeNull
            $result.tables | Should -Not -BeNull
            $result.indices | Should -Not -BeNull
        }

        It 'Includes user table in results' {
            $result = Get-FirebirdDatabaseStatistics -Database $RemoteDatabase -Environment $TestEnvironment
            $result.tables.TableName | Should -Contain 'REMOTE_TEST'
        }
    }

    Context 'Backup-FirebirdDatabase over TCP' {
        BeforeEach {
            $script:RemoteBackupFile = "$RootFolder/remote-backup.fbk"
            if (Test-Path $RemoteBackupFile) {
                Remove-Item -Path $RemoteBackupFile -Force
            }
        }

        It 'Backs up a remote database to local file' {
            $RemoteBackupFile | Should -Not -Exist
            Backup-FirebirdDatabase -Database $RemoteDatabase -BackupFilePath $RemoteBackupFile -Environment $TestEnvironment
            $RemoteBackupFile | Should -Exist
        }

        It 'Returns command-line args for remote backup' {
            $gbakArgs = Backup-FirebirdDatabase -Database $RemoteDatabase -AsCommandLine -Environment $TestEnvironment
            $gbakArgs | Should -Not -BeNullOrEmpty
            # The connection string should appear in the args
            $gbakArgs | Should -Contain $RemoteDatabase.ConnectionString()
        }
    }

    Context 'Restore-FirebirdDatabase over TCP' {
        BeforeAll {
            # Create a backup to restore from
            $script:RestoreBackupFile = "$RootFolder/restore-source.fbk"
            Backup-FirebirdDatabase -Database $RemoteDatabase -BackupFilePath $RestoreBackupFile -Environment $TestEnvironment
        }

        BeforeEach {
            $script:RestoreTargetPath = "$RootFolder/remote-restored.fdb"
            if (Test-Path $RestoreTargetPath) {
                Remove-Item -Path $RestoreTargetPath -Force
            }
        }

        It 'Restores a backup to a remote database target' {
            $remoteTarget = [FirebirdDatabase]::new("localhost/$($Port):$RestoreTargetPath")
            $RestoreTargetPath | Should -Not -Exist
            Restore-FirebirdDatabase -BackupFilePath $RestoreBackupFile -Database $remoteTarget -Environment $TestEnvironment
            $RestoreTargetPath | Should -Exist
        }
    }

    Context 'Convert-FirebirdDatabase over TCP' {
        BeforeEach {
            $script:ConvertTargetPath = "$RootFolder/remote-converted.fdb"
            if (Test-Path $ConvertTargetPath) {
                Remove-Item -Path $ConvertTargetPath -Force
            }
        }

        It 'Converts a remote source database' {
            $remoteTarget = [FirebirdDatabase]::new($ConvertTargetPath)
            $ConvertTargetPath | Should -Not -Exist
            Convert-FirebirdDatabase -SourceDatabase $RemoteDatabase `
                                     -TargetDatabase $remoteTarget `
                                     -SourceEnvironment $TestEnvironment `
                                     -TargetEnvironment $TestEnvironment
            $ConvertTargetPath | Should -Exist
        }
    }

    Context 'New-FirebirdDatabase over TCP' {
        BeforeEach {
            $script:NewRemotePath = "$RootFolder/remote-new.fdb"
            if (Test-Path $NewRemotePath) {
                Remove-Item -Path $NewRemotePath -Force
            }
        }

        It 'Creates a database over a remote connection' {
            $newRemoteDb = [FirebirdDatabase]::new("localhost/$($Port):$NewRemotePath")
            $result = New-FirebirdDatabase -Database $newRemoteDb -Environment $TestEnvironment
            $NewRemotePath | Should -Exist
            $result.Host | Should -Be 'localhost'
            $result.Port | Should -Be "$Port"
            $result.Path | Should -Be $NewRemotePath
        }

        It 'Rejects -Force for remote databases' {
            $newRemoteDb = [FirebirdDatabase]::new("localhost/$($Port):$NewRemotePath")
            { New-FirebirdDatabase -Database $newRemoteDb -Environment $TestEnvironment -Force } |
                Should -Throw '*Cannot use -Force*'
        }
    }

    Context 'Lock and Unlock over TCP' {
        BeforeAll {
            $script:LockDbPath = "$RootFolder/remote-lock.fdb"
            $script:LockRemoteDb = [FirebirdDatabase]::new("localhost/$($Port):$LockDbPath")
            New-FirebirdDatabase -Database $LockRemoteDb -Environment $TestEnvironment | Out-Null
        }

        It 'Locks a remote database' {
            Lock-FirebirdDatabase -Database $LockRemoteDb -Environment $TestEnvironment
            # Verify the database is locked by checking backup state
            $info = Read-FirebirdDatabase -Database $LockRemoteDb -Environment $TestEnvironment
            $info['MON$BACKUP_STATE'] | Should -Not -Be 0
        }

        It 'Unlocks a remote database' {
            Unlock-FirebirdDatabase -Database $LockRemoteDb -Environment $TestEnvironment
            # Verify the database is unlocked
            $info = Read-FirebirdDatabase -Database $LockRemoteDb -Environment $TestEnvironment
            $info['MON$BACKUP_STATE'] | Should -Be 0
        }
    }

    Context 'Remove-FirebirdDatabase rejects remote databases' {
        It 'Throws for remote database' {
            { Remove-FirebirdDatabase -Database $RemoteDatabase -Force } | 
                Should -Throw '*local databases*'
        }
    }
}
