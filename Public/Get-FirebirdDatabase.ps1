function Get-FirebirdDatabase {
    <#
    .SYNOPSIS
        Retrieves information about a Firebird database and its environment.
    .DESCRIPTION
        Returns a FirebirdDatabase object with details about the specified database and environment.
    .PARAMETER DatabasePath
        Path to the Firebird database file to inspect. Must exist.
    .PARAMETER Environment
        The Firebird environment to use. Defaults to the current environment if not specified.
    .EXAMPLE
        Get-FirebirdDatabase -DatabasePath '/tmp/test.fdb' -Environment $fbEnv
        Returns details for the database at '/tmp/test.fdb' using the specified environment.
    .EXAMPLE
        Get-FirebirdDatabase -DatabasePath '/tmp/test.fdb'
        Returns details for the database at '/tmp/test.fdb' using the current environment.
    .OUTPUTS
        FirebirdDatabase object with Environment, DatabasePath, PageSize, and ODSVersion properties.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'The DatabasePath must exist.')]
        [string]$DatabasePath,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    $gstat = $Environment.GetGstatPath()
    Write-VerboseMark -Message "Checking database at '$($DatabasePath)'."

    $output = $query | & $gstat -h $DatabasePath 2>&1

    # Split StdOut and StdErr -- https://stackoverflow.com/a/68106198/33244
    $stdOut, $stdErr = $output.Where({ $_ -is [string] }, 'Split')
    if ($LASTEXITCODE -ne 0) {
        throw $stdErr
    }

    # Parse gstat output. Discard first 5 lines, stop at ODS Version.
    $pageSize = $null
    $odsVersion = $null
    $lines = $stdOut | Select-Object -Skip 5
    foreach ($line in $lines) {
        if ($line -match '^\s+Page size\s+(\d+)') {
            $pageSize = [int]$Matches[1].Trim()
        }

        if ($line -match '^\s+ODS Version\s+([\d]+.[\d]+)') {
            $odsVersion = [version]$Matches[1].Trim()
            break; # Stop processing further lines
        }
    }

    # Return the database information as a FirebirdDatabase class instance.
    [FirebirdDatabase]::new(@{
            Environment  = $Environment
            DatabasePath = $DatabasePath

            PageSize     = $PageSize
            ODSVersion   = $ODSVersion
        })
}
