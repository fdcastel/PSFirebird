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
        # Ensure the environment folder does not exist before each test
        if (Test-Path $TestEnvironmentPath) {
            Remove-Item -Path $TestEnvironmentPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Create a FirebirdEnvironment of the given version' {
        $TestEnvironmentPath | Should -Not -Exist
        $fbEnv = New-FirebirdEnvironment -Version $FirebirdVersion -Path $TestEnvironmentPath
        $fbEnv | Should -BeOfType FirebirdEnvironment
        $TestEnvironmentPath | Should -Exist

        $v = $fbEnv.Version
        [semver]::new($v.Major, $v.Minor, $v.Build) | Should -Be $FirebirdVersion
    }

    It 'Remove a FirebirdEnvironment with -Force' {
        $TestEnvironmentPath | Should -Not -Exist
        New-FirebirdEnvironment -Version $FirebirdVersion -Path $TestEnvironmentPath
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
