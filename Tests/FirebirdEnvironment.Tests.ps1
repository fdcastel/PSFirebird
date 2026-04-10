Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'FirebirdEnvironment' -Tag 'Integration' {
    BeforeAll {
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironmentPath = Join-Path $RootFolder $FirebirdVersion
    }
        
    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Ensure the environment folder does not exist before each test.
        # Retry with a short delay to handle transient file locks (e.g. x64 emulation on ARM64 Windows).
        for ($i = 0; $i -lt 5; $i++) {
            if (-not (Test-Path $TestEnvironmentPath)) { break }
            Remove-Item -Path $TestEnvironmentPath -Recurse -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
    }

    It 'Create a FirebirdEnvironment of the given version' {
        $TestEnvironmentPath | Should -Not -Exist
        $fbEnv = New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams
        $fbEnv | Should -BeOfType FirebirdEnvironment
        $TestEnvironmentPath | Should -Exist

        if (-not $FirebirdBranch) {
            $v = $fbEnv.Version
            [semver]::new($v.Major, $v.Minor, $v.Build) | Should -Be $FirebirdVersion
        }
    }

    It 'Remove a FirebirdEnvironment with -Force' {
        $TestEnvironmentPath | Should -Not -Exist
        New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams
        $TestEnvironmentPath | Should -Exist

        Remove-FirebirdEnvironment -Path $TestEnvironmentPath -Force
        $TestEnvironmentPath | Should -Not -Exist
    }

    It 'Remove a non-environment path throws' {
        $fakePath = Join-Path $RootFolder 'not-a-firebird-env'
        New-Item -ItemType Directory -Path $fakePath -Force > $null
        $fakePath | Should -Exist

        { Remove-FirebirdEnvironment -Path $fakePath -Force } | Should -Throw '*does not appear to be a Firebird environment*'
    }
}
