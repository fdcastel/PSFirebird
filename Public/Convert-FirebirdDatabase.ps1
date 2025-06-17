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
        [object]$SourceEnvironment,
        [object]$TargetEnvironment
    )

    if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
        throw "Database path '$DatabasePath' does not exist."
    }

    $SourceEnvironment ??= Get-FirebirdEnvironment -Verbose:$false
    Write-VerboseMark -Message "Using Firebird environment at '$($SourceEnvironment.Path)'"

    $TargetEnvironment ??= Get-FirebirdEnvironment -Verbose:$false
    Write-VerboseMark -Message "Using Firebird environment at '$($TargetEnvironment.Path)'"

    $v = $TargetEnvironment.Version
    $targetDatabasePath = [Io.Path]::ChangeExtension($DatabasePath, ".FB$($v.Major)$($v.Minor).fdb")

    $backupCmd = $SourceEnvironment.GetGbakPath()
    $backupArgs = Backup-FirebirdDatabase $DatabasePath -AsCommandLine

    $restoreCmd = $TargetEnvironment.GetGbakPath()
    $restoreArgs = Restore-FirebirdDatabase -AsCommandLine -DatabasePath $targetDatabasePath -Force

    & $backupCmd $backupArgs | & $restoreCmd $restoreArgs
}
