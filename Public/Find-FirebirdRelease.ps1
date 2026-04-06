function Find-FirebirdRelease {
    <#
    .SYNOPSIS
        Finds the download URL and metadata for an official Firebird release.
    .DESCRIPTION
        Queries the GitHub API for FirebirdSQL/firebird releases and returns
        the download URL, file name, and version for the matching asset.
    .PARAMETER Version
        The Firebird version to find (minimum 3.0.9), as a [semver] object.
    .PARAMETER RuntimeIdentifier
        The target platform. If not provided, uses the current platform RID.
    .EXAMPLE
        Find-FirebirdRelease -Version '5.0.2' -RuntimeIdentifier 'linux-x64'
    .OUTPUTS
        PSCustomObject with Version, FileName, and Url properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)]
        [semver]$Version,

        [ValidateSet('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier
    )

    $params = @{ Version = $Version }
    if ($RuntimeIdentifier) { $params['RuntimeIdentifier'] = $RuntimeIdentifier }

    Get-FirebirdReleaseUrl @params
}
