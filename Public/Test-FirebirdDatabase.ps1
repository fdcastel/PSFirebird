function Test-FirebirdDatabase {
    <#
    .SYNOPSIS
        Tests whether a Firebird database file is valid and accessible.
    .DESCRIPTION
        Checks if the specified database file exists and can be read by gstat.
        Returns $true if the database is valid and accessible, $false otherwise.
        Useful for CI/CD pipelines and health checks.
    .PARAMETER Database
        The Firebird database to test.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .EXAMPLE
        Test-FirebirdDatabase -Database '/tmp/test.fdb'
        Returns $true if the database is valid.
    .EXAMPLE
        if (Test-FirebirdDatabase -Database $db) { Write-Host 'Database OK' }
        Performs a health check on the database.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    process {
        Write-VerboseMark -Message "Testing database at '$($Database.ConnectionString())'."

        try {
            # A database that gstat can read and that reports an ODS version is valid.
            $header = Get-FirebirdDatabaseHeader -Database $Database -Environment $Environment

            if ($null -eq $header.ODSVersion) {
                Write-VerboseMark -Message 'gstat output did not contain ODS version. Database may be corrupt.'
                return $false
            }

            Write-VerboseMark -Message "Database is valid. ODS Version: $($header.ODSVersion)"
            return $true
        } catch {
            Write-VerboseMark -Message "Database test failed: $($_.Exception.Message)"
            return $false
        }
    }
}
