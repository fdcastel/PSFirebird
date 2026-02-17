function Remove-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Removes a previously created Firebird environment directory.
    .DESCRIPTION
        Validates that the specified path contains a Firebird environment (by checking for gstat binary),
        then recursively removes the directory. Supports -WhatIf and -Confirm for safe operation.
    .PARAMETER Path
        Path to the Firebird environment directory to remove.
    .PARAMETER Force
        Suppresses confirmation prompts.
    .EXAMPLE
        Remove-FirebirdEnvironment -Path '/tmp/firebird-5.0.2'
        Removes the Firebird environment after confirmation.
    .EXAMPLE
        Remove-FirebirdEnvironment -Path '/tmp/firebird-5.0.2' -Force
        Removes the Firebird environment without confirmation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'The path must exist.')]
        [string]$Path,

        [switch]$Force
    )

    process {
        $resolvedPath = Resolve-Path $Path
        Write-VerboseMark -Message "Validating Firebird environment at '$resolvedPath'."

        # Verify this looks like a Firebird environment by checking for gstat
        $gstatPath = if ($global:IsWindows) {
            Join-Path $resolvedPath 'gstat.exe'
        } else {
            Join-Path $resolvedPath 'bin/gstat'
        }

        if (-not (Test-Path $gstatPath)) {
            Write-VerboseMark -Message "gstat not found at '$gstatPath'. Path does not look like a Firebird environment."
            throw "Path '$resolvedPath' does not appear to be a Firebird environment (gstat not found)."
        }

        Write-VerboseMark -Message "Confirmed Firebird environment at '$resolvedPath'."

        if ($Force -or $PSCmdlet.ShouldProcess($resolvedPath, 'Remove Firebird environment')) {
            Write-VerboseMark -Message "Removing environment directory '$resolvedPath'."
            Remove-Item -Path $resolvedPath -Recurse -Force
            Write-VerboseMark -Message "Environment '$resolvedPath' removed successfully."
        }
    }
}
