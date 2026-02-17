Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'FirebirdInstance' -ForEach $FirebirdVersions {
    BeforeAll {
        $script:FirebirdVersion = $_

        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabasePath = "$RootFolder/$FirebirdVersion-tests.fdb"
        $script:TestDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Start a server instance of the given version' {
        $majorVersion = $TestEnvironment.Version.Major
        $Port = 33050 + $majorVersion

        "CREATE OR ALTER USER SYSDBA PASSWORD 'masterkey';" | Invoke-FirebirdIsql -Database $TestDatabase -Environment $TestEnvironment

        $testInstance = Start-FirebirdInstance -Environment $TestEnvironment -Port $Port
        try {
            $testInstance | Should -Not -BeNullOrEmpty
            $testInstance.Environment | Should -Be $TestEnvironment
            $testInstance.Port | Should -Be $Port
            $testInstance.Process | Should -Not -BeNullOrEmpty

            # Wait for the server to start
            Start-Sleep -Seconds 1

            # Ensure the server is running
            $testInstance.Process.HasExited | Should -BeFalse

            # Verify embedded connection
            $embeddedResult = 'SET LIST ON; SELECT mon$remote_protocol FROM mon$attachments WHERE mon$attachment_id = CURRENT_CONNECTION;' | 
                Invoke-FirebirdIsql -Database $TestDatabase -Environment $TestEnvironment
            $embeddedResult | Where-Object { $_ -match 'MON\$REMOTE_PROTOCOL' } |
                Should -Match 'MON\$REMOTE_PROTOCOL\s+<null>'

            # Verify instance connection
            $instanceTestDatabase = "localhost/$($Port):$($TestDatabase.Path)"
            $instanceResult = 'SET LIST ON; SELECT mon$remote_protocol FROM mon$attachments WHERE mon$attachment_id = CURRENT_CONNECTION;' | 
                Invoke-FirebirdIsql -Database $instanceTestDatabase -Environment $TestEnvironment
            $instanceResult | Where-Object { $_ -match 'MON\$REMOTE_PROTOCOL' } |
                Should -Match 'MON\$REMOTE_PROTOCOL\s+TCP.*'
        } finally {
            $testInstance.Process | Stop-Process
        }
    }
}
