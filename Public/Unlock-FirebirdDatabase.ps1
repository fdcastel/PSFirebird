function Unlock-FirebirdDatabase {
    <#
    .SYNOPSIS
        Unlocks a Firebird database after filesystem copy using the nbackup tool.
    .DESCRIPTION
        Uses Firebird's nbackup utility to unlock the specified database after a filesystem-level copy.

        If the database is missing a .delta file, it will attempt to fix it using the -fixup option.
    .PARAMETER Database
        The Firebird database to unlock.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .PARAMETER RemainingArguments
        Additional arguments to pass to the nbackup tool.
    .EXAMPLE
        Unlock-FirebirdDatabase -Database $db -Environment $fbEnv
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_.Path }, ErrorMessage = 'The Database must exist.')]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    $nbackup = $Environment.GetNbackupPath()
    $nbackupArgs = @($RemainingArguments) + @('-unlock', $Database.Path)

    Write-VerboseMark -Message "Calling: $nbackup $nbackupArgs"
    try {
        Invoke-ExternalCommand { & $nbackup @nbackupArgs }
    } catch {
        if ($_.Exception.Message -match 'I/O error during(.*)\.delta') {
            # Database is missing .delta file. Call nbackup with -fixup to fix it.

            $nbackupArgs = @($RemainingArguments) + @('-fixup', $Database.Path)
            Invoke-ExternalCommand { & $nbackup @nbackupArgs }
            return;
        }
        
        if ($_.Exception.Message -match 'Database is not in the physical backup mode') {
            throw 'Database is not locked for backup.'
        }

        throw
    }
}
