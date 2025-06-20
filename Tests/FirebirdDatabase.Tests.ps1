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
        $script:TestDatabase = New-FirebirdDatabase -DatabasePath "$RootFolder/$FirebirdVersion-tests.fdb" -PageSize 4096 -Environment $TestEnvironment
        $script:TestBackupFile = "$RootFolder/$FirebirdVersion-tests.gbk"

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }
        
    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Can read database information' {
        $info = Read-FirebirdDatabase -DatabasePath $TestDatabase.DatabasePath -Environment $TestEnvironment
        $info.Environment | Should -BeOfType FirebirdEnvironment
        $info.DatabasePath | Should -Be $TestDatabase.DatabasePath
        $info['MON$PAGE_SIZE'] | Should -Be 4096
    }
}
