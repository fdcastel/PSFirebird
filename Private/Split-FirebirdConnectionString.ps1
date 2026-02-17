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

    # Remove protocol prefix if present
    $cs = $ConnectionString.Trim()
    $protoMatch = $cs -match '^(?<proto>xnet|inet|inet4|inet6)://(.+)$'
    if ($protoMatch) {
        $proto = $matches['proto']
        $cs = $cs -replace '^(xnet|inet|inet4|inet6)://', ''
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
        if ($cs -match '^(\[(?<host>[^\]]+)\]|(?<host>[^:/]+))(:?(?<port>[^/]+))?/(?<path>.+)$') {
            Write-VerboseMark -Message "Parsed INET connection: Host='$($matches['host'])', Port='$($matches['port'])', Path='$($matches['path'])'"
            return [PSCustomObject]@{
                Protocol = $proto
                Host = $matches['host']
                Port = if ($matches['port']) { $matches['port'].TrimStart(':') } else { $null }
                Path = $matches['path']
            }
        }
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
