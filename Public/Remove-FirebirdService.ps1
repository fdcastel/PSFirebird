function Remove-FirebirdService {
    <#
    .SYNOPSIS
        Removes a Firebird system service.
    .DESCRIPTION
        Stops and unregisters a Firebird service from the system.
        On Windows, uses instsvc.exe to remove the Windows service.
        On Linux, stops, disables, and removes the systemd unit file.
    .PARAMETER Name
        The name of the service to remove. Accepts pipeline input from Get-FirebirdService.
    .PARAMETER Environment
        A Firebird environment whose default service name will be derived and removed.
        Cannot be used together with -Name.
    .PARAMETER Force
        Suppresses confirmation prompts.
    .EXAMPLE
        Remove-FirebirdService -Name 'Firebird-5'
    .EXAMPLE
        Remove-FirebirdService -Environment $fb5
    .EXAMPLE
        Get-FirebirdService | Remove-FirebirdService
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByEnvironment')]
        [FirebirdEnvironment]$Environment,

        [switch]$Force
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByEnvironment') {
            $Name = "Firebird-$($Environment.Version.Major)"
            Write-VerboseMark -Message "Derived service name from environment: $Name"
        }

        if ($IsWindows) {
            Write-VerboseMark -Message "Removing Windows service: $Name"
            $serviceName = "FirebirdServer$Name"

            # Get-Service uses EnumServicesStatus which returns services regardless
            # of their "marked for deletion" state — more reliable than sc.exe query.
            $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if (-not $svc) {
                throw "No Firebird service named '$serviceName' was found."
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove Windows service')) {
                # Stop first (ignore errors if already stopped)
                Write-VerboseMark -Message "Stopping service: Stop-Service '$serviceName'"
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue

                # Delete via sc.exe — avoids Remove-Service wrapper caching that can
                # leave handles open and prevent immediate SCM cleanup.
                Write-VerboseMark -Message "Deleting service via sc.exe delete '$serviceName'"
                $deleteOutput = & sc.exe delete $serviceName 2>&1
                # Accept 1072 (ERROR_SERVICE_MARKED_FOR_DELETE) — service is going away
                if ($LASTEXITCODE -notin @(0, 1072)) {
                    if ($LASTEXITCODE -eq 1060) {
                        throw "No Firebird service named '$serviceName' was found."
                    }
                    throw "Failed to remove Firebird service '$serviceName': $($deleteOutput -join ' ')"
                }

                # Wait until the service disappears from EnumServicesStatus so that
                # re-creating the same name is safe immediately after this call returns.
                $waitEnd = [DateTimeOffset]::Now.AddSeconds(30)
                while ((Get-Service -Name $serviceName -ErrorAction SilentlyContinue) -and
                       [DateTimeOffset]::Now -lt $waitEnd) {
                    Write-VerboseMark -Message "Waiting for SCM to fully remove '$serviceName'..."
                    Start-Sleep -Milliseconds 300
                }
                Write-VerboseMark -Message "Service '$serviceName' fully removed."
            }
        } elseif ($IsLinux) {
            Write-VerboseMark -Message "Removing systemd service: $Name"
            $unitName = $Name.ToLower()
            $unitPath = "/etc/systemd/system/$($unitName).service"

            if (-not (Test-Path $unitPath)) {
                throw "No systemd unit file found at '$unitPath'."
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove systemd service')) {
                # Stop the service (ignore errors if already stopped)
                Write-VerboseMark -Message "Stopping service: systemctl stop $unitName"
                try {
                    Invoke-ExternalCommand { & systemctl stop $unitName }
                } catch {
                    Write-VerboseMark -Message "Service stop returned an error (may already be stopped): $($_.Exception.Message)"
                }

                Write-VerboseMark -Message "Disabling service: systemctl disable $unitName"
                try {
                    Invoke-ExternalCommand { & systemctl disable $unitName }
                } catch {
                    Write-VerboseMark -Message "Service disable returned an error: $($_.Exception.Message)"
                }

                Write-VerboseMark -Message "Removing unit file: $unitPath"
                Remove-Item -Path $unitPath -Force

                Write-VerboseMark -Message 'Running: systemctl daemon-reload'
                Invoke-ExternalCommand { & systemctl daemon-reload } `
                    -ErrorMessage 'Failed to reload systemd daemon'
            }
        } else {
            throw 'Unsupported platform. Only Windows and Linux are supported.'
        }
    }
}
