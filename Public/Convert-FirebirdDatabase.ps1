<#
.SYNOPSIS
Converts a Firebird database to a new version using backup and restore between environments.

.DESCRIPTION
Creates a backup of the specified Firebird database using the source environment and restores it
using the target environment, producing a new database file with a versioned extension.

.PARAMETER DatabasePath
The path to the Firebird database file to convert. This parameter is required and must exist.

.PARAMETER SourceEnvironment
The Firebird environment object to use for the backup operation. Optional.

.PARAMETER TargetEnvironment
The Firebird environment object to use for the restore operation. Optional.

.EXAMPLE
Convert-FirebirdDatabase -DatabasePath 'C:/data/legacy.fdb' -SourceEnvironment $src -TargetEnvironment $tgt

Converts 'legacy.fdb' using the specified source and target environments.

.EXAMPLE
Convert-FirebirdDatabase -DatabasePath 'C:/data/legacy.fdb'

Converts 'legacy.fdb' using the default environments for both backup and restore.

.OUTPUTS
None. Creates a new database file with a versioned extension in the same directory as the source.
#>
function Convert-FirebirdDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DatabasePath,
        [FirebirdEnvironment]$SourceEnvironment = [FirebirdEnvironment]::default(),
        [FirebirdEnvironment]$TargetEnvironment = [FirebirdEnvironment]::default()
    )

    if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
        throw "Database path '$DatabasePath' does not exist."
    }

    Write-VerboseMark -Message "Using source Firebird environment at '$($SourceEnvironment.Path)'"
    Write-VerboseMark -Message "Using target Firebird environment at '$($TargetEnvironment.Path)'"

    $v = $TargetEnvironment.Version
    $targetDatabasePath = [Io.Path]::ChangeExtension($DatabasePath, ".FB$($v.Major)$($v.Minor).fdb")

    $backupCmd = $SourceEnvironment.GetGbakPath()
    $backupArgs = Backup-FirebirdDatabase $DatabasePath -AsCommandLine

    $restoreCmd = $TargetEnvironment.GetGbakPath()
    $restoreArgs = Restore-FirebirdDatabase -AsCommandLine -DatabasePath $targetDatabasePath -Force

    & $backupCmd $backupArgs | & $restoreCmd $restoreArgs
}
