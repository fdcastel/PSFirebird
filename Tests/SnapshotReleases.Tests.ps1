Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Find-FirebirdSnapshotRelease' -Tag 'Unit' {
    BeforeEach {
        Mock Invoke-RestMethod {
            $allReleases = Get-Content "$PSScriptRoot/assets/github-snapshot-releases.json" -Raw | ConvertFrom-Json

            # Extract tag from the URI to return the correct release
            $tag = ($Uri -split '/')[-1]
            $release = $allReleases | Where-Object { $_.tag_name -eq $tag }
            if (-not $release) {
                throw "Release not found for tag: $tag"
            }
            return $release
        } -ModuleName 'PSFirebird'
    }

    It 'Returns snapshot info for v5.0-release linux-x64' {
        $result = Find-FirebirdSnapshotRelease -Branch 'v5.0-release' -RuntimeIdentifier 'linux-x64'
        $result | Should -Not -BeNullOrEmpty
        $result.Branch | Should -Be 'v5.0-release'
        $result.Tag | Should -Be 'snapshot-v5.0-release'
        $result.FileName | Should -BeLike 'Firebird-5.0.*-linux-x64.tar.gz'
        $result.Url | Should -BeLike 'https://github.com/FirebirdSQL/snapshots/releases/download/*'
        $result.Sha256 | Should -Not -BeNullOrEmpty
        $result.UploadedAt | Should -BeOfType [datetime]
    }

    It 'Returns snapshot info for v5.0-release linux-arm64' {
        $result = Find-FirebirdSnapshotRelease -Branch 'v5.0-release' -RuntimeIdentifier 'linux-arm64'
        $result.FileName | Should -BeLike 'Firebird-5.0.*-linux-arm64.tar.gz'
        $result.Sha256 | Should -Not -BeNullOrEmpty
    }

    It 'Returns snapshot info for master linux-x64' {
        $result = Find-FirebirdSnapshotRelease -Branch 'master' -RuntimeIdentifier 'linux-x64'
        $result.Branch | Should -Be 'master'
        $result.Tag | Should -Be 'snapshot-master'
        $result.FileName | Should -BeLike 'Firebird-6.0.*-linux-x64.tar.gz'
        $result.Sha256 | Should -Not -BeNullOrEmpty
    }

    It 'Returns snapshot info for v4.0 linux-x64' {
        $result = Find-FirebirdSnapshotRelease -Branch 'v4.0' -RuntimeIdentifier 'linux-x64'
        $result.Branch | Should -Be 'v4.0'
        $result.Tag | Should -Be 'snapshot-v4.0'
        $result.FileName | Should -BeLike 'Firebird-4.0.*.amd64.tar.gz'
        $result.Sha256 | Should -Not -BeNullOrEmpty
    }

    It 'Throws when no matching asset is found for v4.0 linux-arm64' {
        { Find-FirebirdSnapshotRelease -Branch 'v4.0' -RuntimeIdentifier 'linux-arm64' } |
            Should -Throw "*No 'linux-arm64' asset found*"
    }

    It 'Excludes debug and android assets' {
        $result = Find-FirebirdSnapshotRelease -Branch 'master' -RuntimeIdentifier 'linux-x64'
        $result.FileName | Should -Not -BeLike '*debug*'
        $result.FileName | Should -Not -BeLike '*android*'
    }
}
