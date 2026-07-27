function Split-FirebirdConnectionString {
    <#
    .SYNOPSIS
        Splits a Firebird connection string into Host, Port, and Path components.
    .DESCRIPTION
        Supports all Firebird TCP/IP connection string forms, including inet, inet4, inet6, xnet, and local paths.
    .PARAMETER ConnectionString
        The Firebird connection string to parse.
    .OUTPUTS
        PSCustomObject with Host, Port, and Path properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ConnectionString
    )

    # Remove protocol prefix if present.
    # Longest alternatives first so that 'inet6' is not partially matched as 'inet'.
    $proto = $null
    $cs = $ConnectionString.Trim()
    if ($cs -match '^(?<proto>xnet|inet6|inet4|inet)://(?<rest>.+)$') {
        $proto = $Matches['proto']
        $cs = $Matches['rest']
        Write-VerboseMark -Message "Parsed protocol prefix '$($proto)'. Remainder: '$($cs)'"
    }

    # XNET: xnet://<path-or-alias>
    if ($proto -eq 'xnet') {
        Write-VerboseMark -Message "Parsed XNET connection: Path='$cs'"
        return [PSCustomObject]@{
            Protocol = $proto
            Host = $null
            Port = $null
            Path = $cs
        }
    }

    # Accept local absolute paths (Windows or Linux) before legacy host/path
    if ($cs -match '^(?:[a-zA-Z]:[\\/]|/).+') {
        Write-VerboseMark -Message "Parsed local path connection: Path='$cs'"
        return [PSCustomObject]@{
            Protocol = $null
            Host = $null
            Port = $null
            Path = $cs
        }
    }

    # INET: inet[4|6]://[host[:port]/]path-or-alias
    if ($proto -like 'inet*') {
        if ($cs -match '^(\[(?<host>[^\]]+)\]|(?<host>[^:/]+))(?::(?<port>[^/]+))?/(?<path>.+)$') {
            Write-VerboseMark -Message "Parsed INET connection: Host='$($Matches['host'])', Port='$($Matches['port'])', Path='$($Matches['path'])'"
            return [PSCustomObject]@{
                Protocol = $proto
                Host     = $Matches['host']
                Port     = if ($Matches['port']) { $Matches['port'] } else { $null }
                Path     = $Matches['path']
            }
        }
        Write-VerboseMark -Message "Connection string did not match the INET form. Falling through to legacy parsing."
    }

    # Legacy: <host>[/port]:<path-or-alias>
    if ($cs -match '^(\[(?<host>[^\]]+)\]|(?<host>[^:/]+))(?:/(?<port>[^:]+))?:(?<path>.+)$') {
        Write-VerboseMark -Message "Parsed legacy connection: Host='$($matches['host'])', Port='$($matches['port'])', Path='$($matches['path'])'"
        return [PSCustomObject]@{
            Protocol = 'inet' # Default to inet for legacy format
            Host = $matches['host']
            Port = $matches['port']
            Path = $matches['path']
        }
    }

    throw "Invalid Firebird connection string format: '$ConnectionString'. Expected format: 'inet://host[:port]/path', 'xnet://path', or 'host[/port]:path'."
}
