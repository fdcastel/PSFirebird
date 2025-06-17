function Invoke-FirebirdIsql {
    <#
    .SYNOPSIS
        Executes SQL statements against a Firebird database using isql.
    .DESCRIPTION
        Runs the provided SQL on the specified Firebird database and outputs the result.
    .PARAMETER DatabasePath
        Path to the Firebird database file to connect to.
    .PARAMETER Sql
        The SQL statement(s) to execute. Accepts pipeline input.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .PARAMETER RemainingArguments
        Additional arguments to pass to the isql command.
    .EXAMPLE
        Invoke-FirebirdIsql -DatabasePath '/tmp/test.fdb' -Sql 'SELECT * FROM RDB$DATABASE;'
        Executes the SQL query on the specified database.
    .OUTPUTS
        The output from the isql command.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$DatabasePath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Sql,

        [FirebirdEnvironment]$Environment,

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    $Environment ??= Get-FirebirdEnvironment -Verbose:$false
    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    $isql = $Environment.GetIsqlPath()

    Write-VerboseMark -Message "Piping into: $isql $($RemainingArguments -join ' ') $DatabasePath"
    $Sql | & $isql @RemainingArguments $DatabasePath
}
