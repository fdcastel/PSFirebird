Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Configuration' {
    BeforeAll {
        $script:baseConfig = Join-Path $PSScriptRoot 'assets/firebird.conf'

        $script:testConfig = $null
        $script:tempDir = $null
    }
        
    BeforeEach {
        $tempDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid) -Force
        $testConfig = Join-Path $tempDir 'firebird.conf'
        Copy-Item -Path $baseConfig -Destination $testConfig -Force
    }
    AfterEach {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Returns an empty hashtable for all-commented config' {
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result | Should -BeOfType Hashtable
        $result.Count | Should -Be 0
    }

    It 'Adds a new key' {
        $set = @{ 'TestKey' = 'TestValue' }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result['TestKey'] | Should -Be 'TestValue'
    }

    It 'Updates an existing key' {
        $set = @{ 'TestKey' = 'TestValue' }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set
        $set2 = @{ 'TestKey' = 'NewValue' }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set2
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result['TestKey'] | Should -Be 'NewValue'
    }

    It 'Removes (comments) a key' {
        $set = @{ 'TestKey' = 'TestValue' }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set
        $set2 = @{ 'TestKey' = $null }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set2
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result.ContainsKey('TestKey') | Should -Be $false
    }

    It 'Adds a key that does not exist' {
        $set = @{ 'NonExistentKey' = 'SomeValue' }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result['NonExistentKey'] | Should -Be 'SomeValue'
    }

    It 'Removes (comments) a key that does not exist' {
        $set = @{ 'NonExistentKey' = $null }
        Write-FirebirdConfiguration -Path $testConfig -Configuration $set
        $result = Read-FirebirdConfiguration -Path $testConfig
        $result.ContainsKey('NonExistentKey') | Should -Be $false
    }
}
