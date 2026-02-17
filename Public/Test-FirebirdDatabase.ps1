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
        $dbPath = $Database.Path
        Write-VerboseMark -Message "Testing database at '$dbPath'."

        if (-not (Test-Path $dbPath)) {
            Write-VerboseMark -Message "Database file '$dbPath' does not exist."
            return $false
        }

        try {
            $gstat = $Environment.GetGstatPath()
            Write-VerboseMark -Message "Running gstat header check on '$dbPath'."

            $gstatResult = Invoke-ExternalCommand {
                & $gstat -h $dbPath
            } -Passthru

            # Verify we got valid ODS version from the output
            $hasODS = $false
            foreach ($line in $gstatResult.StdOut) {
                if ($line -match '^\s+ODS Version\s+([\d]+\.[\d]+)') {
                    $hasODS = $true
                    Write-VerboseMark -Message "Database is valid. ODS Version: $($Matches[1])"
                    break
                }
            }

            if (-not $hasODS) {
                Write-VerboseMark -Message "gstat output did not contain ODS version. Database may be corrupt."
                return $false
            }

            return $true
        } catch {
            Write-VerboseMark -Message "Database test failed: $($_.Exception.Message)"
            return $false
        }
    }
}
