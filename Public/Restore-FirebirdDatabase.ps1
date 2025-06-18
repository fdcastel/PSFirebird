function Restore-FirebirdDatabase {
<#!
.SYNOPSIS
Restores a Firebird database from a backup file using gbak.

.DESCRIPTION
Restores a Firebird database from a backup file (.fbk) to a specified database file (.fdb).
Supports restoring from file or pipeline, with options for environment and force overwrite.

.PARAMETER FilePath
The path to the Firebird backup file (.fbk) to restore from. Mandatory unless using -AsCommandLine.

.PARAMETER DatabasePath
The path where the restored database (.fdb) will be created. If not specified, derived from FilePath.

.PARAMETER Environment
The Firebird environment object to use for the restore operation. Optional.

.PARAMETER Force
If specified, overwrites the target database if it already exists.

.PARAMETER AsCommandLine
If specified, returns the gbak command-line arguments instead of running the restore.

.PARAMETER RemainingArguments
Additional arguments to pass to gbak.

.EXAMPLE
Restore-FirebirdDatabase -FilePath 'backup.fbk' -DatabasePath 'restored.fdb'
Restores the backup file 'backup.fbk' to 'restored.fdb'.

.EXAMPLE
Get-Content 'backup.fbk' | Restore-FirebirdDatabase -DatabasePath 'restored.fdb'
Restores a database from backup data provided via pipeline.

.EXAMPLE
Restore-FirebirdDatabase -FilePath 'backup.fbk' -DatabasePath 'restored.fdb' -Force
Restores and overwrites the target database if it exists.

.OUTPUTS
None by default. If -AsCommandLine is used, returns the gbak command-line arguments as a string array.
#>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'FilePath')]
        [string]$FilePath,

        [Parameter(Mandatory, ParameterSetName = 'AsCommandLine')]
        [switch]$AsCommandLine,

        [Parameter(Position = 1, ParameterSetName = 'FilePath')]
        [Parameter(Mandatory, ParameterSetName = 'AsCommandLine')]
        [string]$DatabasePath,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [switch]$Force,

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    # Determine the target database for the restore.
    if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
        if (-not $DatabasePath) {
            throw 'When using the pipeline as input, you must specify a -DatabasePath to restore to.'
        }
        $FilePath = 'stdin'
    } else {
        if (Test-Path $FilePath) {
            Write-VerboseMark -Message "Using file path: $FilePath"
        } else {
            throw "The specified FilePath '$FilePath' does not exist."
        }

        # If no database path is specified, derive it from the file path.
        if (-not $DatabasePath) {
            $DatabasePath = [Io.Path]::ChangeExtension($FilePath, '.restored.fdb')
        }
    }    

    # Force deletion of existing database if specified.
    if ($Force -and $DatabasePath -and (Test-Path $DatabasePath)) {
        Write-VerboseMark -Message "Deleting existing database at '$DatabasePath' due to -Force."
        Remove-Item -Path $DatabasePath -Force
    }

    $gbak = $Environment.GetGbakPath()
    $gbakArgs = $($RemainingArguments) + @(
        '-create_database',
        '-verify',
        '-statistics', 'T',
        $FilePath,
        $DatabasePath
    )

    if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
        Write-VerboseMark -Message "Returning: $gbakArgs"
        return $gbakArgs
    }

    Write-VerboseMark -Message "Calling: $gbak $gbakArgs"
    & $gbak @gbakArgs
}
