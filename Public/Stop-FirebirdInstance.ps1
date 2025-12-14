function Stop-FirebirdInstance {
    <#
    .SYNOPSIS
        Stops a running Firebird server process.
    .DESCRIPTION
        Terminates a Firebird server process by process ID. Can accept pipeline input from Get-FirebirdInstance or any object with an Id property.
    .PARAMETER Id
        The process ID of the Firebird instance to stop.
    .EXAMPLE
        Stop-FirebirdInstance -Id 1234
        Stops the Firebird process with ID 1234.
    .EXAMPLE
        Get-FirebirdInstance | Stop-FirebirdInstance
        Stops all running Firebird instances.
    .EXAMPLE
        Get-FirebirdInstance | Where-Object { $_.Port -eq 3051 } | Stop-FirebirdInstance
        Stops only Firebird instances running on port 3051.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int]$Id
    )

    process {
        Write-VerboseMark -Message "Attempting to stop Firebird process with ID: $($Id)"

        try {
            $process = Get-Process -Id $Id -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess("Firebird process $($Id)", 'Stop process')) {
                $process | Stop-Process -Force
                Write-VerboseMark -Message "Successfully stopped Firebird process with ID: $($Id)"
            }
        }
        catch {
            Write-Error "Failed to stop Firebird process with ID $($Id): $($_.Exception.Message)"
        }
    }
}
