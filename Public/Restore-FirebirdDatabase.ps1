function Restore-FirebirdDatabase {
<#!
.SYNOPSIS
Restores a Firebird database from a backup file using gbak.

.DESCRIPTION
Restores a Firebird database from a backup file (.fbk) to a specified database file (.fdb).
Supports restoring from file or pipeline, with options for environment and force overwrite.

.PARAMETER BackupFilePath
The path to the Firebird backup file (.fbk) to restore from. Mandatory unless using -AsCommandLine.

.PARAMETER Database
The path where the restored database (.fdb) will be created. If not specified, derived from BackupFilePath.

.PARAMETER Environment
The Firebird environment object to use for the restore operation. Optional.

.PARAMETER Force
If specified, overwrites the target database if it already exists.

.PARAMETER AsCommandLine
If specified, returns the gbak command-line arguments instead of running the restore.

.PARAMETER RemainingArguments
Additional arguments to pass to gbak.

.EXAMPLE
Restore-FirebirdDatabase -BackupFilePath 'backup.fbk' -Database 'restored.fdb'
Restores the backup file 'backup.fbk' to 'restored.fdb'.

.EXAMPLE
Get-Content 'backup.fbk' | Restore-FirebirdDatabase -Database 'restored.fdb'
Restores a database from backup data provided via pipeline.

.EXAMPLE
Restore-FirebirdDatabase -BackupFilePath 'backup.fbk' -Database 'restored.fdb' -Force
Restores and overwrites the target database if it exists.

.OUTPUTS
None by default. If -AsCommandLine is used, returns the gbak command-line arguments as a string array.
#>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'BackupFilePath')]
        [string]$BackupFilePath,

        [Parameter(Mandatory, ParameterSetName = 'AsCommandLine')]
        [switch]$AsCommandLine,

        [Parameter(Position = 1, ParameterSetName = 'BackupFilePath')]
        [Parameter(Mandatory, ParameterSetName = 'AsCommandLine')]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [switch]$Force,

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    # Determine the target database for the restore.
    if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
        if (-not $Database) {
            throw 'When using -AsCommandLine, you must specify a -Database to restore to.'
        }
        $BackupFilePath = 'stdin'
    } else {
        if (Test-Path $BackupFilePath) {
            Write-VerboseMark -Message "Using file path: $BackupFilePath"
        } else {
            throw "The specified BackupFilePath '$BackupFilePath' does not exist."
        }

        # If no database path is specified, derive it from the file path.
        if (-not $Database) {
            $databasePath = [Io.Path]::ChangeExtension($BackupFilePath, '.restored.fdb')
            $Database = Get-FirebirdDatabase -Path $databasePath -Environment $Environment
        }
    }    

    # Force deletion of existing database if specified.
    if ($Force -and $Database -and (Test-Path $Database.Path)) {
        Write-VerboseMark -Message "Deleting existing database at '$($Database.Path)' due to -Force."
        Remove-Item -Path $Database.Path -Force
    }

    $gbak = $Environment.GetGbakPath()
    $gbakArgs = $($RemainingArguments) + @(
        '-create_database',
        '-verify',
        '-statistics', 'T',
        $BackupFilePath,
        $Database.Path
    )

    if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
        Write-VerboseMark -Message "Returning: $gbakArgs"
        return $gbakArgs
    }

    Write-VerboseMark -Message "Calling: $gbak $gbakArgs"
    & $gbak @gbakArgs
}
