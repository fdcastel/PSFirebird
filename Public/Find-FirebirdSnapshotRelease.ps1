function Find-FirebirdSnapshotRelease {
    <#
    .SYNOPSIS
        Finds the latest Firebird snapshot build for a given branch and platform.
    .DESCRIPTION
        Queries the GitHub API for FirebirdSQL/snapshots releases and returns
        the download URL, file name, SHA-256 digest, and branch for the matching asset.

        Asset discovery is done by substring matching rather than filename reconstruction,
        making the function robust to upstream naming changes.
    .PARAMETER Branch
        Which snapshot branch to query.
        'master'       - Firebird 6.x development builds  (tag: snapshot-master)
        'v5.0-release' - Firebird 5.x next-patch builds   (tag: snapshot-v5.0-release)
        'v4.0'         - Firebird 4.x next-patch builds   (tag: snapshot-v4.0)
    .PARAMETER RuntimeIdentifier
        The target platform. Defaults to 'linux-x64'.
    .EXAMPLE
        Find-FirebirdSnapshotRelease -Branch 'v5.0-release'
    .EXAMPLE
        Find-FirebirdSnapshotRelease -Branch 'master' -RuntimeIdentifier 'linux-arm64'
    .OUTPUTS
        PSCustomObject with Branch, Tag, FileName, Url, Sha256, and UploadedAt properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('master', 'v5.0-release', 'v4.0')]
        [string]$Branch,

        [ValidateSet('linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier = 'linux-x64'
    )

    $tag = "snapshot-$Branch"

    $apiUrl = "https://api.github.com/repos/FirebirdSQL/snapshots/releases/tags/$tag"
    Write-VerboseMark -Message "Querying GitHub API for snapshot release: $apiUrl"

    $headers = @{ 'User-Agent' = 'PSFirebird' }

    [string]$githubAccessToken = $env:API_GITHUB_ACCESS_TOKEN
    if (-not $githubAccessToken) {
        $githubAccessToken = $env:GITHUB_TOKEN
    }
    if ($githubAccessToken) {
        Write-VerboseMark -Message '- Using authenticated GitHub API requests'
        $headers['Authorization'] = "Bearer $githubAccessToken"
    } else {
        Write-VerboseMark -Message '- Using unauthenticated GitHub API requests (60 req/hour limit)'
    }

    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Verbose:$false
    Write-VerboseMark -Message "Found release: $($release.tag_name) ($($release.name))"

    # Map RuntimeIdentifier to substrings that match asset names across naming conventions.
    # v5/v6: '-linux-x64.tar.gz', '-linux-arm64.tar.gz'
    # v4:    '.amd64.tar.gz' (no arm64 available)
    $ridSubstrings = @{
        'linux-x64'   = @('linux-x64.tar.gz', '.amd64.tar.gz', '.x86_64.tar.gz')
        'linux-arm64'  = @('linux-arm64.tar.gz', '.arm64.tar.gz')
    }

    $substrings = $ridSubstrings[$RuntimeIdentifier]

    $asset = $release.assets | Where-Object {
        $name = $_.name
        $matchesRid = $false
        foreach ($sub in $substrings) {
            if ($name.EndsWith($sub)) {
                $matchesRid = $true
                break
            }
        }
        $matchesRid -and
            $name -notlike '*debugSymbols*' -and
            $name -notlike '*withDebugSymbols*' -and
            $name -notlike '*debuginfo*' -and
            $name -notlike '*android*'
    } | Select-Object -Last 1

    if (-not $asset) {
        throw "No '$RuntimeIdentifier' asset found in snapshot release '$tag'."
    }

    Write-VerboseMark -Message "Selected asset: $($asset.name)"

    $sha256 = if ($asset.digest -match '^sha256:(.+)$') { $Matches[1] } else { $null }

    return [PSCustomObject]@{
        Branch     = $Branch
        Tag        = $tag
        FileName   = $asset.name
        Url        = $asset.browser_download_url
        Sha256     = $sha256
        UploadedAt = if ($asset.updated_at) { [datetime]$asset.updated_at } else { $null }
    }
}
