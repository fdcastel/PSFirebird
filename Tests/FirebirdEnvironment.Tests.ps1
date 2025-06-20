Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

BeforeDiscovery {
    $script:FirebirdVersions = @(
        '3.0.12',
        '4.0.5',
        '5.0.2'
    )
}

Describe 'New-FirebirdEnvironment' -ForEach $FirebirdVersions {
    BeforeAll {
        $script:FirebirdVersion = $_

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
        $env = New-FirebirdEnvironment -Version $FirebirdVersion -Path $TestEnvironmentPath
        $env | Should -BeOfType FirebirdEnvironment
        $TestEnvironmentPath | Should -Exist

        $v = $env.Version
        [semver]::new($v.Major, $v.Minor, $v.Build) | Should -Be $FirebirdVersion
    }
}
