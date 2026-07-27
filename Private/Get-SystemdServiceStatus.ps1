function Get-SystemdServiceStatus {
    <#
    .SYNOPSIS
        Reports whether a systemd unit is currently active.
    .PARAMETER UnitName
        The systemd unit name, without the '.service' suffix.
    .EXAMPLE
        Get-SystemdServiceStatus -UnitName 'firebird-5'
        Returns 'Running' or 'Stopped'.
    .OUTPUTS
        'Running' or 'Stopped'.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$UnitName
    )

    # `systemctl is-active` exits non-zero for every inactive state (inactive, failed,
    # unknown), so the exit code is the answer and a non-zero one is not an error here.
    $result = Invoke-ExternalCommand { & systemctl is-active $UnitName } -SuccessExitCodes @(0, 1, 3, 4) -Passthru
    $status = if ($result.ExitCode -eq 0) { 'Running' } else { 'Stopped' }

    Write-VerboseMark -Message "Unit '$($UnitName)' is $($status) (systemctl is-active: $($result.StdOut))."
    return $status
}
