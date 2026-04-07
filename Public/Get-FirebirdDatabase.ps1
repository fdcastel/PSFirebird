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

        $header = Get-FirebirdDatabaseHeader -Database $Database -Environment $Environment

        # Return the database information as a FirebirdDatabase class instance.
        [FirebirdDatabase]::new(@{
                Protocol    = $Database.Protocol
                Host        = $Database.Host
                Port        = $Database.Port
                Path        = $Database.Path

                PageSize    = $header.PageSize
                ODSVersion  = $header.ODSVersion
            })
    }
}
