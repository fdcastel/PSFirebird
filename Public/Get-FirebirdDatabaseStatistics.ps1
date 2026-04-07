<#
.SYNOPSIS
Retrieves statistics for a Firebird database using gstat.

.DESCRIPTION
Runs the Firebird gstat utility with -a (analyze) and -r (record versions) flags to collect
database statistics, then parses the output into structured objects.

.PARAMETER Database
The Firebird database to analyze. Accepts pipeline input.

.PARAMETER TableName
Optional list of table names to restrict the analysis to.

.PARAMETER Environment
The Firebird environment object to use. Optional.

.EXAMPLE
Get-FirebirdDatabaseStatistics -Database 'database.fdb'
Returns statistics for all tables and indices in the database.

.EXAMPLE
Get-FirebirdDatabaseStatistics -Database 'database.fdb' -TableName 'CUSTOMERS', 'ORDERS'
Returns statistics only for the CUSTOMERS and ORDERS tables and their indices.

.OUTPUTS
PSCustomObject with 'tables' and 'indices' properties containing the parsed gstat output.
#>

function Get-FirebirdDatabaseStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [FirebirdDatabase]$Database,

        [string[]]$TableName,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    $gstat = $Environment.GetGstatPath()
    $gstatArgs = @(
        '-a'
        '-r'
        foreach ($table in $TableName) {
            '-t'
            $table
        }
        $Database.ConnectionString()
    )

    Write-VerboseMark -Message "Calling: $gstat $gstatArgs"
    & $gstat @gstatArgs | ConvertFrom-Gstat
}
