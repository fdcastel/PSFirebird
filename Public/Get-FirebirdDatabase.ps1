function Get-FirebirdDatabase {
    <#
    .SYNOPSIS
        Retrieves information about a Firebird database and its environment.
    .DESCRIPTION
        Returns a FirebirdDatabase object with details about the specified database and environment.
        Supports both local and remote databases via connection strings.
    .PARAMETER Database
        The Firebird database to inspect. Accepts connection strings, paths, or FirebirdDatabase objects.
    .PARAMETER Environment
        The Firebird environment to use. Defaults to the current environment if not specified.
    .EXAMPLE
        Get-FirebirdDatabase -Database '/tmp/test.fdb' -Environment $fbEnv
        Returns details for the database at '/tmp/test.fdb' using the specified environment.
    .EXAMPLE
        Get-FirebirdDatabase -Database 'localhost:/tmp/test.fdb'
        Returns details for a remote database using the current environment.
    .EXAMPLE
        Get-ChildItem *.fdb | Get-FirebirdDatabase
        Returns details for all .fdb files in the current directory.
    .OUTPUTS
        FirebirdDatabase object with Environment and database connection properties.
    #>

    [CmdletBinding()]
    [OutputType([FirebirdDatabase])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName', 'Path')]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    process {
        Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

        $connectionString = $Database.ConnectionString()
        $gstat = $Environment.GetGstatPath()
        Write-VerboseMark -Message "Checking database at '$connectionString'."

        $gstatResult = Invoke-ExternalCommand {
            & $gstat -h $connectionString
        } -Passthru

        # Parse gstat output. Discard first 5 lines, stop at ODS Version.
        $pageSize = $null
        $odsVersion = $null
        $lines = $gstatResult.StdOut | Select-Object -Skip 5
        foreach ($line in $lines) {
            if ($line -match '^\s+Page size\s+(\d+)') {
                $pageSize = [int]$Matches[1].Trim()
                Write-VerboseMark -Message "Parsed Page size: $pageSize"
            }

            if ($line -match '^\s+ODS Version\s+([\d]+.[\d]+)') {
                $odsVersion = [version]$Matches[1].Trim()
                Write-VerboseMark -Message "Parsed ODS Version: $odsVersion"
                break; # Stop processing further lines
            }
        }

        # Return the database information as a FirebirdDatabase class instance.
        [FirebirdDatabase]::new(@{
                Protocol    = $Database.Protocol
                Host        = $Database.Host
                Port        = $Database.Port
                Path        = $Database.Path

                PageSize    = $PageSize
                ODSVersion  = $ODSVersion
            })
    }
}
