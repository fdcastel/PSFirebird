<#
.SYNOPSIS
Returns information about a Firebird database and its environment.

.DESCRIPTION
Get details about a Firebird database, including environment, page size, charset, and more.

.PARAMETER DatabasePath
The path to the Firebird database file to inspect.

.PARAMETER Environment
The Firebird environment to use. If not specified, uses the current environment.

.EXAMPLE
Get-FirebirdDatabase -DatabasePath '/tmp/test.fdb' -Environment $fbEnv

.EXAMPLE
Get-FirebirdDatabase -DatabasePath '/tmp/test.fdb'

.OUTPUTS
PSCustomObject with properties: Environment, DatabasePath, PageSize, Charset, User, RawInfo.
#>
function Get-FirebirdDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$DatabasePath,

        [FirebirdEnvironment]$Environment
    )

    if (-not $Environment) {
        $Environment = Get-FirebirdEnvironment
    }
    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    $isql = $Environment.GetIsqlPath()

    Write-VerboseMark -Message "Querying database at '$($DatabasePath)'."
    $query = 'SET LIST ON; SELECT * FROM mon$database CROSS JOIN rdb$database;'
    $output = $query | & $isql -bail -quiet $DatabasePath 2>&1

    # Split StdOut and StdErr -- https://stackoverflow.com/a/68106198/33244
    $stdOut, $stdErr = $output.Where({ $_ -is [string] }, 'Split')
    if ($LASTEXITCODE -ne 0) {
        throw $stdErr
    }

    # Parse isql list output. Discard first 2 lines, stop at first blank line.
    $rawInfo = [ordered]@{}
    $tableLines = $stdOut | Select-Object -Skip 2
    foreach ($line in $tableLines) {
        if ($line.Trim() -eq '') { break }
        if ($line -match '^(\S+)\s+(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            $rawInfo[$key] = $value
        }
    }

    [PSCustomObject]@{
        Environment  = $Environment
        DatabasePath = $DatabasePath

        PageSize     = $rawInfo['MON$PAGE_SIZE']
        Charset      = $rawInfo['RDB$CHARACTER_SET_NAME']
        User         = $rawInfo['MON$OWNER']

        RawInfo      = $rawInfo
    }
}
