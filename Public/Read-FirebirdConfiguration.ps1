function Read-FirebirdConfiguration {
    <#
    .SYNOPSIS
    Reads all active (non-commented) configuration entries from a Firebird config file.

    .DESCRIPTION
    Returns a hashtable of key/value pairs for all settings that are not commented out in the file.
    Useful for retrieving the current effective configuration from a Firebird configuration file.

    .PARAMETER Path
    The path to the Firebird configuration file to read.

    .OUTPUTS
    Hashtable. Each key is a configuration entry, and each value is its corresponding setting.

    .EXAMPLE
    Read-FirebirdConfiguration -Path 'C:/Firebird/firebird.conf'
    Returns all active configuration entries from the specified file as a hashtable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    $config = @{}
    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }
    $lines = Get-Content -Path $Path
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith('#')) {
            $match = $trimmed -match '^(\S+)\s*=\s*(.*)$'
            Write-VerboseMark -Message "Processing line: $trimmed (match: $match)"
            if ($match) {
                $key = $Matches[1]
                $value = $Matches[2]
                $config[$key] = $value
            }
        }
    }
    return $config
}
