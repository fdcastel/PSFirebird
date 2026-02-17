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
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_.Path }, ErrorMessage = 'The Database must exist.')]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    $nbackup = $Environment.GetNbackupPath()
    $nbackupArgs = @($RemainingArguments) + @('-lock', $Database.Path)

    Write-VerboseMark -Message "Calling: $nbackup $nbackupArgs"
    if ($PSCmdlet.ShouldProcess($Database.Path, 'Lock Firebird database for backup')) {
        try {
            Invoke-ExternalCommand { & $nbackup @nbackupArgs } -Passthru
        } catch {
            if ($_.Exception.Message -match 'Database is already in the physical backup mode') {
                Write-VerboseMark -Message 'Database is already in physical backup mode.'
                throw 'Database is already locked for backup.'
            }

            throw
        }
    }
}
