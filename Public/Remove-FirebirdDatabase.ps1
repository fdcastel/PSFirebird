function Remove-FirebirdDatabase {
    <#
    .SYNOPSIS
        Safely removes a Firebird database file.
    .DESCRIPTION
        Removes a Firebird database file after verifying it is not locked for backup.
        Supports -WhatIf and -Confirm for safe operation.
    .PARAMETER Database
        The Firebird database to remove. Must exist.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .PARAMETER Force
        Suppresses confirmation prompts.
    .EXAMPLE
        Remove-FirebirdDatabase -Database '/tmp/test.fdb'
        Removes the specified database after confirmation.
    .EXAMPLE
        Remove-FirebirdDatabase -Database '/tmp/test.fdb' -Force
        Removes the specified database without confirmation.
    .EXAMPLE
        Get-ChildItem *.fdb | ForEach-Object { [FirebirdDatabase]::new($_.FullName) } | Remove-FirebirdDatabase
        Removes all .fdb files in the current directory.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_.Path }, ErrorMessage = 'The Database must exist.')]
        [FirebirdDatabase]$Database,

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [switch]$Force
    )

    process {
        $dbPath = $Database.Path
        Write-VerboseMark -Message "Attempting to remove database at '$dbPath'."

        # Check for .delta file which indicates the database is locked for backup
        $deltaFile = "$dbPath.delta"
        if (Test-Path $deltaFile) {
            Write-VerboseMark -Message "Delta file detected at '$deltaFile'. Database is locked."
            throw "Cannot remove database '$dbPath'. It is currently locked for backup (.delta file exists). Use Unlock-FirebirdDatabase first."
        }

        if ($Force -or $PSCmdlet.ShouldProcess($dbPath, 'Remove Firebird database')) {
            Write-VerboseMark -Message "Removing database file '$dbPath'."
            Remove-Item -Path $dbPath -Force
            Write-VerboseMark -Message "Database '$dbPath' removed successfully."
        }
    }
}
