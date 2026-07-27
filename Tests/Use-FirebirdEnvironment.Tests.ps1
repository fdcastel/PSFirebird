Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Use-FirebirdEnvironment' -Tag 'Unit' {
    BeforeAll {
        # Create mock environments for testing
        $script:mockEnv3 = [FirebirdEnvironment]::new(@{
                Path    = '/tmp/mock-firebird-3.0.12'
                Version = [version]'3.0.12'
            })

        $script:mockEnv4 = [FirebirdEnvironment]::new(@{
                Path    = '/tmp/mock-firebird-4.0.5'
                Version = [version]'4.0.5'
            })

        $script:mockEnv5 = [FirebirdEnvironment]::new(@{
                Path    = '/tmp/mock-firebird-5.0.2'
                Version = [version]'5.0.2'
            })

        # FirebirdEnvironment::default() falls back to $env:FIREBIRD_ENVIRONMENT before
        # throwing, so every 'no environment available' assertion below depends on that
        # variable being unset. Isolate the whole suite from the developer's session --
        # the README actively recommends setting it.
        $script:OriginalFirebirdEnvironment = $env:FIREBIRD_ENVIRONMENT
    }

    AfterAll {
        if ($null -eq $script:OriginalFirebirdEnvironment) {
            Remove-Item env:FIREBIRD_ENVIRONMENT -ErrorAction SilentlyContinue
        } else {
            $env:FIREBIRD_ENVIRONMENT = $script:OriginalFirebirdEnvironment
        }
    }

    BeforeEach {
        # Also clears anything a preceding test set.
        Remove-Item env:FIREBIRD_ENVIRONMENT -ErrorAction SilentlyContinue
    }

    It 'FirebirdEnvironment::default() throws an error when no context environment is available.' {
        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'FirebirdEnvironment::default() uses the context environment when available.' {
        Use-FirebirdEnvironment -Environment $mockEnv5 {
            [FirebirdEnvironment]::default() | Should -Be $mockEnv5
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'Use-FirebirdEnvironment accepts pipeline input.' {
        $mockEnv4 | Use-FirebirdEnvironment -ScriptBlock {
            [FirebirdEnvironment]::default() | Should -Be $mockEnv4
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'Context environments can be nested.' {
        Use-FirebirdEnvironment -Environment $mockEnv3 {
            [FirebirdEnvironment]::default() | Should -Be $mockEnv3

            Use-FirebirdEnvironment -Environment $mockEnv4 {
                [FirebirdEnvironment]::default() | Should -Be $mockEnv4

                Use-FirebirdEnvironment -Environment $mockEnv5 {
                    [FirebirdEnvironment]::default() | Should -Be $mockEnv5
                }

                [FirebirdEnvironment]::default() | Should -Be $mockEnv4
            }

            [FirebirdEnvironment]::default() | Should -Be $mockEnv3
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'FirebirdEnvironment::default() uses FIREBIRD_ENVIRONMENT env var as fallback.' {
        # BeforeEach clears the variable and AfterAll restores the original.
        $env:FIREBIRD_ENVIRONMENT = '/tmp/mock-firebird-from-env'

        $result = [FirebirdEnvironment]::default()
        $result.Path | Should -Be '/tmp/mock-firebird-from-env'
    }

    It 'FirebirdEnvironment::default() prefers context environment over FIREBIRD_ENVIRONMENT env var.' {
        $env:FIREBIRD_ENVIRONMENT = '/tmp/mock-firebird-from-env'

        Use-FirebirdEnvironment -Environment $mockEnv5 {
            $result = [FirebirdEnvironment]::default()
            $result | Should -Be $mockEnv5
        }
    }

    It 'Nested context environments can overlap.' {
        Use-FirebirdEnvironment -Environment $mockEnv3 {
            [FirebirdEnvironment]::default() | Should -Be $mockEnv3

            Use-FirebirdEnvironment -Environment $mockEnv4 {
                [FirebirdEnvironment]::default() | Should -Be $mockEnv4

                Use-FirebirdEnvironment -Environment $mockEnv3 {
                    [FirebirdEnvironment]::default() | Should -Be $mockEnv3
                }

                [FirebirdEnvironment]::default() | Should -Be $mockEnv4

                Use-FirebirdEnvironment -Environment $mockEnv5 {
                    [FirebirdEnvironment]::default() | Should -Be $mockEnv5
                }

                [FirebirdEnvironment]::default() | Should -Be $mockEnv4
            }

            [FirebirdEnvironment]::default() | Should -Be $mockEnv3
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }    
}
