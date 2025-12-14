function Invoke-FirebirdIsql {
    <#
    .SYNOPSIS
        Executes SQL statements against a Firebird database using isql.
    .DESCRIPTION
        Runs the provided SQL on the specified Firebird database and outputs the result.
    .PARAMETER Database
        Path to the Firebird database file to connect to.
    .PARAMETER Sql
        The SQL statement(s) to execute. Accepts pipeline input.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .PARAMETER RemainingArguments
        Additional arguments to pass to the isql command.
    .EXAMPLE
        Invoke-FirebirdIsql -Database '/tmp/test.fdb' -Sql 'SELECT * FROM RDB$DATABASE;'
        Executes the SQL query on the specified database.
    .OUTPUTS
        The output from the isql command.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [FirebirdDatabase]$Database,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Sql,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    $isql = $Environment.GetIsqlPath()

    $connectionString = $Database.ConnectionString()
    Write-VerboseMark -Message "Piping Sql into: $isql $($RemainingArguments -join ' ') $connectionString"

    $result = Invoke-ExternalCommand {
        $Sql | & $isql @RemainingArguments $connectionString
    } -Passthru -ErrorMessage "Error running isql."    

    return $result.StdOut
}
