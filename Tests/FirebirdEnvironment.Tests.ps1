Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'New-FirebirdEnvironment (existing path)' -Tag 'Unit' {
    # These need no Firebird download: with -Version, the existing-path check happens
    # before any network call.
    BeforeAll {
        $script:UnitRoot = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)
    }

    AfterAll {
        Remove-Item -Path $UnitRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Reports an empty directory as unusable rather than a bare gstat failure.' {
        $stalePath = Join-Path $UnitRoot (New-Guid)
        New-Item -ItemType Directory -Path $stalePath > $null

        { New-FirebirdEnvironment -Version '5.0.3' -Path $stalePath } |
            Should -Throw '*is not a usable Firebird environment*'
    }

    It 'Reports a partially extracted directory as unusable.' {
        # The real-world case: an interrupted install leaves gstat behind without the
        # libraries it links against, so the binary exists but cannot run.
        $stalePath = Join-Path $UnitRoot (New-Guid)
        $gstatPath = [FirebirdEnvironment]::ExpectedToolPath($stalePath, 'gstat')
        New-Item -ItemType Directory -Path (Split-Path $gstatPath -Parent) -Force > $null
        Set-Content -Path $gstatPath -Value 'not a real executable'

        { New-FirebirdEnvironment -Version '5.0.3' -Path $stalePath } |
            Should -Throw '*is not a usable Firebird environment*'
    }

    It 'Points at -Force as the way out, and keeps the underlying cause.' {
        $stalePath = Join-Path $UnitRoot (New-Guid)
        New-Item -ItemType Directory -Path $stalePath > $null

        $message = try { New-FirebirdEnvironment -Version '5.0.3' -Path $stalePath } catch { $_.Exception.Message }

        $message | Should -BeLike '*Use -Force to replace it*'
        $message | Should -BeLike '*Cause:*' -Because 'the original failure is still worth reporting'
    }
}

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

    It 'Get-FirebirdEnvironment does not leak a non-zero $LASTEXITCODE' {
        New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams | Out-Null

        $global:LASTEXITCODE = 0
        Get-FirebirdEnvironment -Path $TestEnvironmentPath | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'New-FirebirdEnvironment (reuse existing path) does not leak a non-zero $LASTEXITCODE' {
        New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams | Out-Null

        $global:LASTEXITCODE = 0
        New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'GetClientLibraryPath returns the client library file' {
        $fbEnv = New-FirebirdEnvironment @FirebirdEnvParams -Path $TestEnvironmentPath @FirebirdExtraParams

        $clientLib = $fbEnv.GetClientLibraryPath()

        $clientLib | Should -Not -BeNullOrEmpty
        $clientLib | Should -Exist
        if ($IsWindows) {
            $clientLib.Path | Should -Match 'fbclient\.dll$'
        } else {
            $clientLib.Path | Should -Match 'libfbclient\.so'
        }
    }
}
