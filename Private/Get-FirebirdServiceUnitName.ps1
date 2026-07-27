function Get-FirebirdServiceUnitName {
    <#
    .SYNOPSIS
        Maps a Firebird service name to its systemd unit name.
    .DESCRIPTION
        Linux services are discovered with the glob 'firebird-*.service', mirroring the
        'FirebirdServer*' prefix used on Windows. A service whose name does not already
        start with 'firebird-' therefore has to be prefixed, or Get-FirebirdService would
        never list it.

        The default name produced by New-FirebirdService is 'Firebird-{Major}', which
        already carries the prefix, so the common case is unchanged.
    .PARAMETER Name
        The Firebird service name (e.g. 'Firebird-5' or 'MyFirebird').
    .EXAMPLE
        Get-FirebirdServiceUnitName -Name 'Firebird-5'
        Returns 'firebird-5'.
    .EXAMPLE
        Get-FirebirdServiceUnitName -Name 'MyFirebird'
        Returns 'firebird-myfirebird'.
    .OUTPUTS
        The systemd unit name, without the '.service' suffix.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    $unitName = $Name.ToLower()
    if (-not $unitName.StartsWith('firebird-')) {
        $unitName = "firebird-$unitName"
        Write-VerboseMark -Message "Service name '$($Name)' does not carry the 'firebird-' prefix. Using unit name '$($unitName)'."
    }

    return $unitName
}
