function Get-FirebirdReleaseUrl {
    <#
    .SYNOPSIS
        Returns the download URL for the Firebird Embedded package for a given version and runtime identifier (RID).
    .PARAMETER Version
        The Firebird version to install (minimum 3.0.9), as a [semver] object.
    .PARAMETER RuntimeIdentifier
        Optional. The runtime identifier (RID) to use. If not provided, uses the current platform RID.
    .OUTPUTS
        [string] The download URL for the Firebird Embedded package.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [semver]$Version,
        
        [Parameter()]
        [ValidateSet('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier
    )

    # Cannot use [ValidateRange()] or [ValidateScript()] directly on [semver] parameters
    $minVersion = [semver]'3.0.9'
    if ($Version -lt $minVersion) {
        throw 'Firebird minimal supported version is 3.0.9.'
    }

    if (-not $RuntimeIdentifier) {
        $RuntimeIdentifier = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier
    }
    Write-VerboseMark "Requested Firebird version: $($Version), RID: $RuntimeIdentifier"

    $supportedRIDs = @('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')
    if ($supportedRIDs -notcontains $RuntimeIdentifier) {
        throw "Unsupported RuntimeIdentifier: $RuntimeIdentifier. Supported: $($supportedRIDs -join ', ')"
    }

    $apiUrl = 'https://api.github.com/repos/FirebirdSQL/firebird/releases'
    Write-VerboseMark "Querying GitHub API: $apiUrl"
    $releases = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'PSFirebird' }

    $versionString = $Version.ToString()
    $release = $releases | Where-Object { $_.tag_name -match $versionString }
    if (-not $release) {
        throw "Could not find Firebird release for version $versionString on GitHub."
    }
    Write-VerboseMark "Found release: $($release.tag_name)"

    $asset = $null
    $major = $Version.Major
    $patternMap = @{}
    switch ($major) {
        5 {
            $patternMap = @{
                'win-x86'     = 'windows-x86.*\.zip$'
                'win-x64'     = 'windows-x64.*\.zip$'
                'win-arm64'   = 'windows-arm64.*\.zip$'
                'linux-x64'   = 'linux-x64.*\.tar\.gz$'
                'linux-arm64' = 'linux-arm64.*\.tar\.gz$'
            }
        }
        4 {
            $patternMap = @{
                'win-x86'     = 'Win32.*\.zip$'
                'win-x64'     = 'x64.*\.zip$'
                'linux-x64'   = 'amd64.*\.tar\.gz$|x86_64.*\.tar\.gz$'
                'linux-arm64' = 'arm64.*\.tar\.gz$'
            }
        }
        3 {
            $patternMap = @{
                'win-x86'     = 'Win32.*\.zip$'
                'win-x64'     = 'x64.*\.zip$'
                'linux-x64'   = 'amd64.*\.tar\.gz$|x86_64.*\.tar\.gz$'
                'linux-arm64' = 'arm64.*\.tar\.gz$'
            }
        }
        default {
            throw "Unsupported Firebird major version: $major"
        }
    }
    $pattern = $patternMap[$RuntimeIdentifier]
    if ($RuntimeIdentifier -like 'linux-*') {
        $asset = $release.assets |
            Where-Object { $_.name -match $pattern -and $_.name -notmatch 'debug|symbols|pdb' -and $_.name -notmatch 'android' }
    } else {
        $asset = $release.assets |
            Where-Object { $_.name -match $pattern -and $_.name -notmatch 'debug|symbols|pdb' }
    }
    if (-not $asset) {
        throw "Could not find a suitable asset for $RuntimeIdentifier in release $versionString."
    }

    Write-VerboseMark "Selected asset: $($asset[0].name)"
    return $asset[0].browser_download_url
}
