<#
.SYNOPSIS
    Reads and returns detailed information about a Firebird database and its environment.
.DESCRIPTION
    Retrieves properties from MON$DATABASE and RDB$DATABASE for the specified database.
.PARAMETER DatabasePath
    Path to the Firebird database file to inspect.
.PARAMETER Environment
    Firebird environment to use. Uses the current environment if not specified.
.EXAMPLE
    Read-FirebirdDatabase -DatabasePath '/tmp/test.fdb' -Environment $fbEnv
    Returns details for the database at '/tmp/test.fdb' using the specified environment.
.EXAMPLE
    Read-FirebirdDatabase -DatabasePath '/tmp/test.fdb'
    Returns details for the database at '/tmp/test.fdb' using the current environment.
.OUTPUTS
    Hashtable with properties from MON$DATABASE and RDB$DATABASE system tables.
#>
function Read-FirebirdDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string]$DatabasePath,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    Write-VerboseMark -Message "Querying database at '$($DatabasePath)'."
    $query = 'SET LIST ON; SELECT * FROM mon$database CROSS JOIN rdb$database;'
    $isql = $Environment.GetIsqlPath()
    $output = $query | & $isql -bail -quiet $DatabasePath 2>&1

    # Split StdOut and StdErr -- https://stackoverflow.com/a/68106198/33244
    $stdOut, $stdErr = $output.Where({ $_ -is [string] }, 'Split')
    if ($LASTEXITCODE -ne 0) {
        throw $stdErr
    }

    # Parse isql list output. Discard first 2 lines, stop at first blank line.
    $result = [ordered]@{
        Environment  = $Environment
        DatabasePath = $DatabasePath
    }
    $resultLines = $stdOut | Select-Object -Skip 2
    foreach ($line in $resultLines) {
        if ($line.Trim() -eq '') { break }
        if ($line -match '^(\S+)\s+(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            $result[$key] = $value
        }
    }

    return $result
}
