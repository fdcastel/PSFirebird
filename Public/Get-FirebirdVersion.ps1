function Get-FirebirdVersion {
    <#
    .SYNOPSIS
        Parses a Firebird version string into a structured object.
    .DESCRIPTION
        Parses version strings produced by Firebird tools (gstat -z, isql -z, etc.)
        into a structured object with platform, version, build number, and server name.

        Accepts version strings in the format:
        - 'LI-V5.0.3.1683 Firebird 5.0'
        - 'WI-V4.0.5.3140 Firebird 4.0'
        - 'LI-V3.0.12.33787 Firebird 3.0'

        Also accepts just the version prefix (e.g. 'LI-V5.0.3.1683').
    .PARAMETER VersionString
        The Firebird version string to parse. Can be piped.
    .EXAMPLE
        Get-FirebirdVersion 'LI-V5.0.3.1683 Firebird 5.0'
    .EXAMPLE
        'WI-V4.0.5.3140 Firebird 4.0' | Get-FirebirdVersion
    .OUTPUTS
        PSCustomObject with Platform, Version, Build, and ServerName properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$VersionString
    )

    process {
        if ($VersionString -notmatch '^(LI|WI)-V(\d+\.\d+\.\d+)\.(\d+)(.*)$') {
            throw "Cannot parse Firebird version string: '$VersionString'"
        }

        $platform = switch ($Matches[1]) {
            'LI' { 'Linux' }
            'WI' { 'Windows' }
        }

        $version = [semver]$Matches[2]
        $build = [int]$Matches[3]
        $remainder = $Matches[4].Trim()
        $serverName = if ($remainder -ne '') { $remainder } else { $null }

        [PSCustomObject]@{
            Platform   = $platform
            Version    = $version
            Build      = $build
            ServerName = $serverName
        }
    }
}
