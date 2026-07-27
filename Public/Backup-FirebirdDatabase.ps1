<#
.SYNOPSIS
Creates a backup of a Firebird database using gbak.

.DESCRIPTION
Backs up a Firebird database to a file or as a byte stream. Supports force overwrite and transportable mode.

.PARAMETER Database
The path to the Firebird database to back up. Accepts pipeline input.

.PARAMETER BackupFilePath
The path to the backup file to create. Required unless -AsCommandLine is used.

.PARAMETER AsCommandLine
If specified, returns the gbak command-line arguments instead of running the backup.

.PARAMETER Environment
The Firebird environment object to use for the backup. Optional.

.PARAMETER Force
If specified, overwrites the backup file if it already exists.

.PARAMETER Transportable
If specified, creates a transportable backup (removes the -nt option from gbak).

.PARAMETER RemainingArguments
Additional arguments to pass to gbak.

.EXAMPLE
Backup-FirebirdDatabase -Database 'database.fdb' -BackupFilePath 'backup.fbk'
Backs up 'database.fdb' to 'backup.fbk'.

.EXAMPLE
'database.fdb' | Backup-FirebirdDatabase -BackupFilePath 'backup.fbk'
Backs up a database using pipeline input.

.EXAMPLE
Backup-FirebirdDatabase 'database.fdb' -AsCommandLine
Returns the gbak command-line arguments for the backup operation.

.OUTPUTS
None by default. If -AsCommandLine is used, returns the gbak command-line arguments as a string array.

.NOTES
PowerShell does not support binding positional parameters after pipeline input. For example,

    'database.fdb' | Backup-FirebirdDatabase -BackupFilePath 'backup.fbk'

works, but

    'database.fdb' | Backup-FirebirdDatabase 'backup.fbk'

will prompt for BackupFilePath.
#>

function Backup-FirebirdDatabase {
    [CmdletBinding(DefaultParameterSetName = 'BackupFilePath', SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'BackupFilePath')]
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'AsCommandLine')]
        [FirebirdDatabase]$Database,

        [Parameter(Position = 1, ParameterSetName = 'BackupFilePath')]
        [Alias('BackupFile')]
        [string]$BackupFilePath,

        [Parameter(Mandatory, ParameterSetName = 'AsCommandLine')]
        [switch]$AsCommandLine,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [switch]$Force,

        [switch]$Transportable,

        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )

    begin {
        Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"
        $gbak = $Environment.GetGbakPath()

        # Using -NT option makes backup 5% faster (tested with a 320GB database)
        if ($Transportable) {
            Write-VerboseMark -Message 'Using transportable backup (no -nt).'
        }
    }

    process {
        # Determine the target output for the backup.
        # $targetPath is derived per pipeline item, so $BackupFilePath is left untouched.
        if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
            $targetPath = 'stdout'
        } else {
            # If no file path is specified, derive it from the database path.
            $targetPath = if ($BackupFilePath) {
                $BackupFilePath
            } else {
                [Io.Path]::ChangeExtension($Database.Path, '.fbk')
            }
        }

        # Using -G option inhibits Firebird garbage collection, speeding up the backup process if a lot of updates have been done.
        #   https://firebirdsql.org/file/documentation/html/en/firebirddocs/gbak/firebird-gbak.html#gbak-backup-speedup

        $gbakArgs = @(
            $RemainingArguments
            '-backup_database'
            '-g'
            if (-not $Transportable) { '-nt' }
            '-verify'
            '-statistics', 'T'
            $Database.ConnectionString()
            $targetPath
        ) | Where-Object { $null -ne $_ -and $_ -ne '' }

        if ($PSCmdlet.ParameterSetName -eq 'AsCommandLine') {
            Write-VerboseMark -Message "Returning: $gbakArgs"
            return $gbakArgs
        }

        Write-VerboseMark -Message "Calling: $gbak $gbakArgs"
        if ($PSCmdlet.ShouldProcess($Database.Path, 'Backup Firebird database')) {
            # Force deletion of existing file if specified. Inside the gate so -WhatIf
            # cannot delete.
            if ($Force -and (Test-Path $targetPath)) {
                Write-VerboseMark -Message "Deleting existing file at '$($targetPath)' due to -Force."
                Remove-Item -Path $targetPath -Force
            }

            Invoke-ExternalCommand {
                & $gbak @gbakArgs
            } -ErrorMessage 'Error running gbak backup.'
        }
    }
}
