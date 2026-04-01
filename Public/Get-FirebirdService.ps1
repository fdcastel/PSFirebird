function Get-FirebirdService {
    <#
    .SYNOPSIS
        Gets information about registered Firebird system services.
    .DESCRIPTION
        Returns details of Firebird services registered on the system.
        On Windows, queries the Windows Service Control Manager.
        On Linux, enumerates systemd unit files.
    .PARAMETER Name
        Optional service name filter. If not specified, returns all Firebird services.
    .EXAMPLE
        Get-FirebirdService
        Returns all registered Firebird services.
    .EXAMPLE
        Get-FirebirdService -Name 'Firebird-5'
        Returns information about the Firebird-5 service.
    .OUTPUTS
        PSCustomObject with Name, Status, Port, and EnvironmentPath properties.
    #>
    [CmdletBinding()]
    param(
        [string]$Name
    )

    if ($IsWindows) {
        Write-VerboseMark -Message 'Querying Windows services'

        $serviceFilter = if ($Name) { "FirebirdServer$Name" } else { 'FirebirdServer*' }
        Write-VerboseMark -Message "Service filter: $serviceFilter"

        $services = Get-Service -Name $serviceFilter -ErrorAction SilentlyContinue
        if (-not $services) {
            Write-VerboseMark -Message 'No matching Firebird services found.'
            return
        }

        foreach ($svc in $services) {
            # Derive the Firebird service name from the Windows service name (strip 'FirebirdServer' prefix)
            $fbName = $svc.Name -replace '^FirebirdServer', ''
            Write-VerboseMark -Message "Found service: $($svc.Name) (Firebird name: $fbName)"

            # Try to find the environment path from the service binary path
            $envPath = $null
            $port = $null
            try {
                $wmiSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
                if ($wmiSvc -and $wmiSvc.PathName) {
                    # PathName looks like: "C:\path\to\firebird.exe" -S ServiceName -p Port
                    $binaryPath = ($wmiSvc.PathName -split '"')[1]
                    if ($binaryPath) {
                        $envPath = Split-Path $binaryPath -Parent
                        Write-VerboseMark -Message "Environment path from binary: $envPath"

                        # Read port from firebird.conf
                        $confPath = Join-Path $envPath 'firebird.conf'
                        if (Test-Path $confPath) {
                            $config = Read-FirebirdConfiguration -Path $confPath
                            $port = if ($config['RemoteServicePort']) { [int]$config['RemoteServicePort'] } else { $null }
                            Write-VerboseMark -Message "Port from config: $port"
                        } else {
                            Write-VerboseMark -Message "firebird.conf not found at: $confPath"
                        }
                    }
                }
            } catch {
                Write-VerboseMark -Message "Could not determine environment path: $($_.Exception.Message)"
            }

            [PSCustomObject]@{
                Name            = $fbName
                Status          = $svc.Status.ToString()
                Port            = $port
                EnvironmentPath = $envPath
            }
        }
    } elseif ($IsLinux) {
        Write-VerboseMark -Message 'Querying systemd units'

        $unitDir = '/etc/systemd/system'
        $pattern = if ($Name) { "$($Name.ToLower()).service" } else { 'firebird-*.service' }
        Write-VerboseMark -Message "Looking for unit files matching: $pattern"

        $unitFiles = Get-ChildItem -Path $unitDir -Filter $pattern -ErrorAction SilentlyContinue
        if (-not $unitFiles) {
            Write-VerboseMark -Message 'No matching Firebird unit files found.'
            return
        }

        foreach ($unitFile in $unitFiles) {
            $fbName = $unitFile.BaseName
            Write-VerboseMark -Message "Found unit file: $($unitFile.Name)"

            $envPath = $null
            $port = $null

            # Parse the unit file for Description, ExecStart and WorkingDirectory
            $content = Get-Content -Path $unitFile.FullName
            foreach ($line in $content) {
                $trimmed = $line.Trim()
                # Recover original-case name from Description: "Firebird X.Y.Z ... ({Name})"
                if ($trimmed -match '^Description=.*\((.+)\)$') {
                    $fbName = $Matches[1]
                    Write-VerboseMark -Message "Original service name from Description: $fbName"
                }
                if ($trimmed -match '^ExecStart=.*-p\s+(\d+)') {
                    $port = [int]$Matches[1]
                    Write-VerboseMark -Message "Port from ExecStart: $port"
                }
                if ($trimmed -match '^WorkingDirectory=(.+)$') {
                    $envPath = $Matches[1]
                    Write-VerboseMark -Message "Environment path from WorkingDirectory: $envPath"
                }
            }

            # Query service status
            $null = & systemctl is-active $fbName 2>&1
            $status = if ($LASTEXITCODE -eq 0) { 'Running' } else { 'Stopped' }
            Write-VerboseMark -Message "Service status: $status"

            [PSCustomObject]@{
                Name            = $fbName
                Status          = $status
                Port            = $port
                EnvironmentPath = $envPath
            }
        }
    } else {
        throw 'Unsupported platform. Only Windows and Linux are supported.'
    }
}
