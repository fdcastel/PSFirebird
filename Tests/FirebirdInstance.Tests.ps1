Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'FirebirdInstance' -Tag 'Integration' {
    BeforeAll {
        $script:Fixture = New-TestFixture
        $script:RootFolder = $Fixture.RootFolder
        $script:TestEnvironment = $Fixture.Environment
        $script:TestDatabase = $Fixture.Database
        $script:TestDatabasePath = $TestDatabase.Path
    }

    AfterAll {
        Remove-TestFixture -Fixture $Fixture
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
            # Exercises Stop-FirebirdInstance rather than calling Stop-Process directly.
            $testInstance.Process | Stop-FirebirdInstance
        }
    }

    It 'Get-FirebirdInstance lists a running instance, and Stop-FirebirdInstance stops it' {
        $port = 33150 + $TestEnvironment.Version.Major
        $instance = Start-FirebirdInstance -Environment $TestEnvironment -Port $port
        try {
            $found = Get-FirebirdInstance | Where-Object Id -EQ $instance.Process.Id
            $found | Should -Not -BeNullOrEmpty -Because 'the instance just started must be listed'
            [int]$found.Port | Should -Be $port

            $instance.Process | Stop-FirebirdInstance
            $instance.Process.WaitForExit(10000) | Should -BeTrue

            Get-FirebirdInstance | Where-Object Id -EQ $instance.Process.Id | Should -BeNullOrEmpty
        } finally {
            if (-not $instance.Process.HasExited) { $instance.Process | Stop-Process -Force -ErrorAction SilentlyContinue }
        }
    }
}
