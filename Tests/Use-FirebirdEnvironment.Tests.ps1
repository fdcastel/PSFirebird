Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Use-FirebirdEnvironment' {
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
