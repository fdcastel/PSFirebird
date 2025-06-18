<#
.SYNOPSIS
Performs a backup and restore cycle on a Firebird database. Useful for migrating between Firebird versions.

.DESCRIPTION
Creates a backup of the specified Firebird database from the source environment and restores it to the target environment.

This function exists only because PowerShell pipelines do not support raw binary streams; otherwise, 
the output of Backup-FirebirdDatabase could simply be piped directly into Restore-FirebirdDatabase.

(...and **believe me**, I tried!)

.PARAMETER SourceDatabase
The path to the Firebird database file to convert. This parameter is required and must exist.

.PARAMETER SourceDatabase
The path to the Firebird database file to create. If not specified, the function will create a new database file with a versioned extension in the same directory as the source database.

.PARAMETER SourceEnvironment
The Firebird environment object to use for the backup operation. Optional.

.PARAMETER TargetEnvironment
The Firebird environment object to use for the restore operation. Optional.

.PARAMETER Force
If specified, overwrites the target database if it already exists.

.EXAMPLE
Convert-FirebirdDatabase -SourceDatabase 'C:/data/legacy.fdb' -SourceEnvironment $src -TargetEnvironment $tgt

Converts 'legacy.fdb' using the specified source and target environments.

.EXAMPLE
Convert-FirebirdDatabase -SourceDatabase 'C:/data/legacy.fdb'

Converts 'legacy.fdb' using the default environments for both backup and restore.

.OUTPUTS
None. Creates a new database file with a versioned extension in the same directory as the source.
#>
function Convert-FirebirdDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceDatabase,

        [string]$TargetDatabase,

        [FirebirdEnvironment]$SourceEnvironment = [FirebirdEnvironment]::default(),

        [FirebirdEnvironment]$TargetEnvironment = [FirebirdEnvironment]::default(),

        [switch]$Force
    )

    if (-not (Test-Path -Path $SourceDatabase -PathType Leaf)) {
        throw "Database path '$SourceDatabase' does not exist."
    }
    Write-VerboseMark -Message "Source environment at '$($SourceEnvironment.Path)'"
    Write-VerboseMark -Message "Source database is '$($SourceDatabase)'"

    $v = $TargetEnvironment.Version
    if (-not $TargetDatabase) {
        $TargetDatabase = [Io.Path]::ChangeExtension($SourceDatabase, ".FB$($v.Major)$($v.Minor).fdb")
    }
    Write-VerboseMark -Message "Target environment at '$($TargetEnvironment.Path)'"
    Write-VerboseMark -Message "Target database is '$($TargetDatabase)'"

    $backupCmd = $SourceEnvironment.GetGbakPath()
    $backupArgs = Backup-FirebirdDatabase -DatabasePath $SourceDatabase -AsCommandLine -Environment $SourceEnvironment

    $restoreCmd = $TargetEnvironment.GetGbakPath()
    $restoreArgs = Restore-FirebirdDatabase -AsCommandLine -DatabasePath $TargetDatabase -Environment $SourceEnvironment -Force:$Force

    & $backupCmd $backupArgs | & $restoreCmd $restoreArgs
}
