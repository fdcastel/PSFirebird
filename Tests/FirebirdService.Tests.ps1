Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

# Elevation check must be at describe-scope (not in BeforeAll) so that -Skip:($script:SkipTests)
# is correctly evaluated during Pester v5 discovery phase.
$script:SkipTests = if ($IsWindows) {
    -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    (& id -u) -ne '0'
}

Describe 'FirebirdService' -Tag 'Integration' {
    BeforeAll {
        if ($script:SkipTests) { return }

        # Helper: pick a random port in the dynamic/private range
        function Get-RandomPort {
            Get-Random -Minimum 49152 -Maximum 65536
        }

        # Create a temporary folder for test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment @FirebirdEnvParams @FirebirdExtraParams
        $script:TestDatabasePath = "$RootFolder/$FirebirdVersion-service-tests.fdb"
        $script:TestDatabase = New-FirebirdDatabase -Database $TestDatabasePath -Environment $TestEnvironment

        # Set SYSDBA password for remote connections
        "CREATE OR ALTER USER SYSDBA PASSWORD 'masterkey';" | Invoke-FirebirdIsql -Database $TestDatabase -Environment $TestEnvironment

        # Set up environment variables for Firebird authentication
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'
    }

    AfterAll {
        if ($script:SkipTests) { return }

        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Create a service with default name and custom port' -Skip:($SkipTests) {
        $port = Get-RandomPort
        $defaultName = "Firebird-$($TestEnvironment.Version.Major)"

        New-FirebirdService -Environment $TestEnvironment -Port $port > $null
        try {
            $result = Get-FirebirdService -Name $defaultName

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $defaultName
            $result.Port | Should -Be $port
            $result.EnvironmentPath | Should -Be $TestEnvironment.Path
            $result.Status | Should -Be 'Running'

            # Verify TCP connection through the service
            $remoteDatabase = "localhost/$($port):$($TestDatabase.Path)"
            $tcpResult = 'SET LIST ON; SELECT mon$remote_protocol FROM mon$attachments WHERE mon$attachment_id = CURRENT_CONNECTION;' |
                Invoke-FirebirdIsql -Database $remoteDatabase -Environment $TestEnvironment
            $tcpResult | Where-Object { $_ -match 'MON\$REMOTE_PROTOCOL' } |
                Should -Match 'MON\$REMOTE_PROTOCOL\s+TCP.*'
        } finally {
            try { Remove-FirebirdService -Name $defaultName -Force } catch { }
        }
    }

    It 'Get service info after creation' -Skip:($SkipTests) {
        $port = Get-RandomPort
        $defaultName = "Firebird-$($TestEnvironment.Version.Major)"

        New-FirebirdService -Environment $TestEnvironment -Port $port > $null
        try {
            $svcInfo = Get-FirebirdService -Name $defaultName
            $svcInfo | Should -Not -BeNullOrEmpty
            $svcInfo.Name | Should -Be $defaultName
            $svcInfo.Port | Should -Be $port
            $svcInfo.Status | Should -Be 'Running'
        } finally {
            try { Remove-FirebirdService -Name $defaultName -Force } catch { }
        }
    }

    It 'Remove a service' -Skip:($SkipTests) {
        $port = Get-RandomPort
        # Use unique name to avoid SCM "marked for deletion" state from previous test
        $customName = "FBRemove-$($TestEnvironment.Version.Major)-$(Get-Random -Minimum 1000 -Maximum 9999)"

        New-FirebirdService -Environment $TestEnvironment -Port $port -Name $customName > $null
        try {
            # Verify it exists
            $svcBefore = Get-FirebirdService -Name $customName
            $svcBefore | Should -Not -BeNullOrEmpty

            # Remove it
            Remove-FirebirdService -Name $customName -Force

            # Verify it no longer exists
            $svcAfter = Get-FirebirdService -Name $customName
            $svcAfter | Should -BeNullOrEmpty
        } finally {
            # Idempotent: no-op if already removed above
            try { Remove-FirebirdService -Name $customName -Force } catch { }
        }
    }

    It 'Create a service with custom name' -Skip:($SkipTests) {
        $port = Get-RandomPort
        $customName = "TestFB-$(Get-Random -Minimum 1000 -Maximum 9999)"

        New-FirebirdService -Environment $TestEnvironment -Port $port -Name $customName > $null
        try {
            $result = Get-FirebirdService -Name $customName
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $customName
            $result.Port | Should -Be $port
        } finally {
            try { Remove-FirebirdService -Name $customName -Force } catch { }
        }
    }

    It 'Creating duplicate service throws' -Skip:($SkipTests) {
        $port = Get-RandomPort
        $defaultName = "Firebird-$($TestEnvironment.Version.Major)"

        New-FirebirdService -Environment $TestEnvironment -Port $port > $null
        try {
            # Attempt to create a duplicate should throw
            { New-FirebirdService -Environment $TestEnvironment -Port $port } |
                Should -Throw '*already exists*'
        } finally {
            try { Remove-FirebirdService -Name $defaultName -Force } catch { }
        }
    }

    It 'Removing non-existent service throws' -Skip:($SkipTests) {
        { Remove-FirebirdService -Name 'NonExistentFirebird-99999' -Force } |
            Should -Throw
    }

    It 'Create service with -NoStart flag' -Skip:($SkipTests) {
        $port = Get-RandomPort
        $customName = "TestFBNoStart-$(Get-Random -Minimum 1000 -Maximum 9999)"

        New-FirebirdService -Environment $TestEnvironment -Port $port -Name $customName -NoStart > $null
        try {
            $result = Get-FirebirdService -Name $customName
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $customName
            $result.Status | Should -Be 'Stopped'
        } finally {
            try { Remove-FirebirdService -Name $customName -Force } catch { }
        }
    }

    It 'Remove service using -Environment parameter' -Skip:($SkipTests) {
        $port = Get-RandomPort
        # The -Environment parameter derives the name as 'Firebird-{Major}'
        $derivedName = "Firebird-$($TestEnvironment.Version.Major)"

        New-FirebirdService -Environment $TestEnvironment -Port $port > $null
        try {
            # Remove using -Environment (internally derives 'Firebird-{Major}' as the name)
            Remove-FirebirdService -Environment $TestEnvironment -Force

            # Verify it no longer exists
            $svcAfter = Get-FirebirdService -Name $derivedName
            $svcAfter | Should -BeNullOrEmpty
        } finally {
            # Idempotent: no-op if already removed above
            try { Remove-FirebirdService -Name $derivedName -Force } catch { }
        }
    }
}
