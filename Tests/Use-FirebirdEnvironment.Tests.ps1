Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Use-FirebirdEnvironment' {
    BeforeAll {
        # Create mock environments for testing
        $script:mockEnv1 = [FirebirdEnvironment]::new(@{
            Path = 'C:/TestFirebird/3.0'
            Version = [version]'3.0.12'
        })

        $script:mockEnv2 = [FirebirdEnvironment]::new(@{
            Path = 'C:/TestFirebird/5.0'
            Version = [version]'5.0.2'
        })
    }

    It 'FirebirdEnvironment::default() throws an error when no context environment is available.' {
        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'FirebirdEnvironment::default() uses the context environment when available.' {
        Use-FirebirdEnvironment -Environment $mockEnv2 {
            $capturedEnv = [FirebirdEnvironment]::default()
            $capturedEnv | Should -Be $mockEnv2
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'Context environments can be nested.' {
        Use-FirebirdEnvironment -Environment $mockEnv1 {
            $outerEnv = [FirebirdEnvironment]::default()
            $outerEnv | Should -Be $mockEnv1

            Use-FirebirdEnvironment -Environment $mockEnv2 {
                $innerEnv = [FirebirdEnvironment]::default()
                $innerEnv | Should -Be $mockEnv2
            }

            $restoredEnv = [FirebirdEnvironment]::default()
            $restoredEnv | Should -Be $mockEnv1  # Should be restored
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'Use-FirebirdEnvironment accepts pipeline input.' {
        $mockEnv1 | Use-FirebirdEnvironment -ScriptBlock {
            $env = [FirebirdEnvironment]::default()
            $env | Should -Be $mockEnv1
        }

        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }
}
