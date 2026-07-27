function Find-FirebirdRelease {
    <#
    .SYNOPSIS
        Finds the download URL and metadata for an official Firebird release.
    .DESCRIPTION
        Queries the GitHub API for FirebirdSQL/firebird releases and returns
        the download URL, file name, version, and SHA-256 digest for the matching asset.
        The SHA-256 digest is available for releases published from July 2025 onward;
        older releases return $null for the Sha256 property.
    .PARAMETER Version
        The Firebird version to find (minimum 3.0.9), as a [semver] object.
    .PARAMETER RuntimeIdentifier
        The target platform. If not provided, uses the current platform RID.
    .EXAMPLE
        Find-FirebirdRelease -Version '5.0.2' -RuntimeIdentifier 'linux-x64'
    .OUTPUTS
        PSCustomObject with Version, FileName, Url, and Sha256 properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [semver]$Version,

        [ValidateSet('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier
    )

    # Cannot use [ValidateRange()] or [ValidateScript()] directly on [semver] parameters
    $minVersion = [semver]'3.0.9'
    if ($Version -lt $minVersion) {
        throw 'Firebird minimal supported version is 3.0.9.'
    }

    if (-not $RuntimeIdentifier) {
        # Only reachable when the RID was not supplied, so ValidateSet has not vetted it.
        $RuntimeIdentifier = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier
        $supportedRIDs = @('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')
        if ($supportedRIDs -notcontains $RuntimeIdentifier) {
            throw "Unsupported RuntimeIdentifier: $RuntimeIdentifier. Supported: $($supportedRIDs -join ', ')"
        }
    }
    Write-VerboseMark -Message "Requested Firebird version: $($Version), RID: $($RuntimeIdentifier)"

    $apiUrl = 'https://api.github.com/repos/FirebirdSQL/firebird/releases'
    Write-VerboseMark -Message "Querying GitHub API for releases: $($apiUrl)"

    $releases = Invoke-RestMethod -Uri "$apiUrl`?per_page=100" -Headers (Get-GitHubApiHeader) -Verbose:$false

    $versionString = $Version.ToString()
    $release = $releases | Where-Object { $_.tag_name -match "^[vVR]?$([regex]::Escape($versionString))(\.|$)" }
    if (-not $release) {
        throw "Could not find Firebird release for version $versionString on GitHub."
    }
    Write-VerboseMark -Message "Found release: $($release.tag_name)"

    $major = $Version.Major
    $patternMap = switch ($major) {
        { $_ -ge 6 } {
            Write-VerboseMark -Message "Using v6+ asset naming convention for Firebird $($major).x"
            @{
                'win-x86'     = 'windows-x86.*\.zip$'
                'win-x64'     = 'windows-x64.*\.zip$'
                'win-arm64'   = 'windows-arm64.*\.zip$'
                'linux-x64'   = 'linux-x64.*\.tar\.gz$'
                'linux-arm64' = 'linux-arm64.*\.tar\.gz$'
            }
            break
        }
        5 {
            Write-VerboseMark -Message "Using v5 asset naming convention for Firebird $($major).x"
            @{
                'win-x86'     = 'windows-x86.*\.zip$'
                'win-x64'     = 'windows-x64.*\.zip$'
                'linux-x64'   = 'linux-x64.*\.tar\.gz$'
                'linux-arm64' = 'linux-arm64.*\.tar\.gz$'
                # win-arm64 intentionally absent: Firebird v5 never published Windows ARM64 binaries
            }
            break
        }
        { $_ -in 3, 4 } {
            Write-VerboseMark -Message "Using v3/v4 asset naming convention for Firebird $($major).x"
            @{
                'win-x86'     = 'Win32.*\.zip$'
                'win-x64'     = 'x64.*\.zip$'
                'linux-x64'   = 'amd64.*\.tar\.gz$|x86_64.*\.tar\.gz$'
                'linux-arm64' = 'arm64.*\.tar\.gz$'
            }
            break
        }
        default {
            throw "Unsupported Firebird major version: $major"
        }
    }

    if (-not $patternMap.ContainsKey($RuntimeIdentifier)) {
        throw "RuntimeIdentifier '$RuntimeIdentifier' is not supported for Firebird $major.x."
    }

    # 'android' only ever appears in Linux asset names, so one filter covers both branches.
    $pattern = $patternMap[$RuntimeIdentifier]
    $asset = $release.assets |
        Where-Object { $_.name -match $pattern -and $_.name -notmatch 'debug|symbols|pdb|android' }

    if (-not $asset) {
        throw "Could not find a suitable asset for $RuntimeIdentifier in release $versionString."
    }

    $selectedAsset = @($asset)[0]
    Write-VerboseMark -Message "Selected asset: $($selectedAsset.name)"

    return [PSCustomObject]@{
        Version  = $Version
        FileName = $selectedAsset.name
        Url      = $selectedAsset.browser_download_url
        Sha256   = if ($selectedAsset.digest -match '^sha256:(.+)$') { $Matches[1] } else { $null }
    }
}
