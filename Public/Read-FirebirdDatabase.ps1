<#
.SYNOPSIS
    Reads and returns detailed information about a Firebird database and its environment.
.DESCRIPTION
    Retrieves properties from MON$DATABASE and RDB$DATABASE for the specified database.
.PARAMETER Database
    Path to the Firebird database file to inspect.
.PARAMETER Environment
    Firebird environment to use. Uses the current environment if not specified.
.EXAMPLE
    Read-FirebirdDatabase -Database '/tmp/test.fdb' -Environment $fbEnv
    Returns details for the database at '/tmp/test.fdb' using the specified environment.
.EXAMPLE
    Read-FirebirdDatabase -Database '/tmp/test.fdb'
    Returns details for the database at '/tmp/test.fdb' using the current environment.
.OUTPUTS
    Hashtable with properties from MON$DATABASE and RDB$DATABASE system tables.
#>
function Read-FirebirdDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    $query = 'SET LIST ON; SELECT * FROM mon$database CROSS JOIN rdb$database;'

    $isqlOutput = $query | Invoke-FirebirdIsql -Database $Database -Environment $Environment -bail -quiet 

    # Parse isql list output. Discard first 2 lines, stop at first blank line.
    $result = [ordered]@{
        Environment  = $Environment
        Database = $Database
    }

    $resultLines = $isqlOutput | Select-Object -Skip 2
    foreach ($line in $resultLines) {
        if ($line.Trim() -eq '') { break }
        if ($line -match '^(\S+)\s+(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            Write-VerboseMark -Message "Parsed: $key = $value"
            $result[$key] = $value
        }
    }

    return $result
}
