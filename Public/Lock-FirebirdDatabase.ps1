function Lock-FirebirdDatabase {
    <#
    .SYNOPSIS
        Locks a Firebird database for filesystem copy using the nbackup tool.
    .DESCRIPTION
        Uses Firebird's nbackup utility to lock the specified database for safe filesystem-level copying.
    .PARAMETER Database
        The Firebird database to lock.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .PARAMETER RemainingArguments
        Additional arguments to pass to the nbackup tool.
    .EXAMPLE
        Lock-FirebirdDatabase -Database $db -Environment $fbEnv
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    if (-not (Test-Path $Database.Path)) {
        throw "Database file '$($Database.Path)' does not exist."
    }

    $nbackup = $Environment.GetNbackupPath()
    $nbackupArgs = @($RemainingArguments) + @('-lock', $Database.Path)

    Write-VerboseMark -Message "Calling: $nbackup $nbackupArgs"
    try {
        Invoke-ExternalCommand { & $nbackup @nbackupArgs } -Passthru
    } catch {
        if ($_.Exception.Message -match 'Database is already in the physical backup mode') {
            throw 'Database is already locked for backup.'
        }

        throw
    }
}
