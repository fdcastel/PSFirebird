function Invoke-ExternalCommand(
    [Parameter(Mandatory)]
    [scriptblock]$Command,
    [int[]]$SuccessExitCodes = @(0),
    [string]$ErrorMessage,
    [switch]$Passthru
) {
    $stdoutAndErr = & $Command 2>&1

    # Split stdout and stderr -- https://stackoverflow.com/a/68106198/33244
    #   The [string[]] cast converts the [ErrorRecord] instances to strings too.
    $stdout, [string[]]$stderr = $stdoutAndErr.Where({ $_ -is [string] }, 'Split')
    if ($SuccessExitCodes -notcontains $LASTEXITCODE) {
        # If the command failed, we throw an exception with the stderr output.

        if (-not $ErrorMessage) {
            $ErrorMessage = "Command exited with code $LASTEXITCODE."
        }

        $exceptionMessages = @()
        if ($stderr) {
            $exceptionMessages = @("$ErrorMessage. Output is:") + $stderr
        }

        throw $($exceptionMessages -join [Environment]::NewLine)
    }

    if ($Passthru) {
        # If the Passthru switch is specified, we return both stdout and stderr.
        return [PSCustomObject]@{
            StdOut = $stdout
            StdErr = $stderr
            ExitCode = $LASTEXITCODE
        }
    }
}
