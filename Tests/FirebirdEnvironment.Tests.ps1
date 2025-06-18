Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'FirebirdEnvironment' {
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

    It 'FirebirdEnvironment::default() uses context environment when available' {
        $capturedEnv = $null
        
        Use-FirebirdEnvironment -Environment $mockEnv2 {
            $capturedEnv = [FirebirdEnvironment]::default()
            $capturedEnv | Should -Be $mockEnv2
        }
    }
    
    It 'FirebirdEnvironment::default() throws clear error when no context environment available' {
        { [FirebirdEnvironment]::default() } | Should -Throw 'No Firebird environment available*'
    }

    It 'Inner context overrides outer context in static method' {
        $outerEnv = $null
        $innerEnv = $null
        $restoredEnv = $null
        
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
    }
}
