function New-FirebirdService {
    <#
    .SYNOPSIS
        Registers a Firebird environment as a system service.
    .DESCRIPTION
        Installs a Firebird server as a system service (Windows Service or systemd unit on Linux).
        Configures the listening port in firebird.conf and optionally starts the service.
    .PARAMETER Environment
        The Firebird environment to register as a service.
    .PARAMETER Port
        The TCP port for the Firebird service to listen on. Defaults to 3050.
    .PARAMETER Name
        The service name. Defaults to 'Firebird-{MajorVersion}' (e.g., 'Firebird-5').
    .PARAMETER NoStart
        If specified, the service is registered but not started.
    .EXAMPLE
        $fb5 = New-FirebirdEnvironment -Version '5.0.3'
        New-FirebirdService -Environment $fb5 -Port 3055
    .EXAMPLE
        New-FirebirdService -Environment $fb5 -Port 3055 -Name 'MyFirebird' -NoStart
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [FirebirdEnvironment]$Environment,

        [int]$Port = 3050,

        [string]$Name,

        [switch]$NoStart
    )

    if (-not $Name) {
        $Name = "Firebird-$($Environment.Version.Major)"
        Write-VerboseMark -Message "No name specified. Using default: $Name"
    }

    if (-not (Test-Path $Environment.Path)) {
        throw "Environment path does not exist: $($Environment.Path)"
    }

    $firebirdConfPath = Join-Path $Environment.Path 'firebird.conf'
    if (-not (Test-Path $firebirdConfPath)) {
        throw "firebird.conf not found at: $firebirdConfPath"
    }

    if ($IsWindows) {
        Write-VerboseMark -Message 'Registering Windows service'
        $serverPath = $Environment.GetServerPath()

        # Check for existing service with same name before modifying any config.
        # firebird.exe registers with StartServiceCtrlDispatcher as 'FirebirdServer{instance}'
        # where instance is set via the -S flag. So the SCM service name must match.
        $existingService = Get-Service -Name "FirebirdServer$Name" -ErrorAction SilentlyContinue
        if ($existingService) {
            throw "A service named 'FirebirdServer$Name' already exists. Remove it first with Remove-FirebirdService."
        }

        # Configure the listening port in firebird.conf
        Write-VerboseMark -Message "Setting RemoteServicePort to $Port in $firebirdConfPath"
        Write-FirebirdConfiguration -Path $firebirdConfPath -Configuration @{ RemoteServicePort = $Port }

        if ($PSCmdlet.ShouldProcess($Name, 'Install Windows service')) {
            # Register firebird.exe directly as a Windows service.
            # The -S flag sets the instance name that firebird.exe passes to StartServiceCtrlDispatcher,
            # which must match the registered service name 'FirebirdServer{Name}'.
            $binPath = "`"$serverPath`" -S $Name -p $Port"
            Write-VerboseMark -Message "Registering service 'FirebirdServer$Name' with binary: $binPath"
            New-Service -Name "FirebirdServer$Name" `
                -DisplayName "Firebird Server - $Name" `
                -Description "Firebird Database Server on port $Port" `
                -BinaryPathName $binPath `
                -StartupType Automatic | Out-Null

            if (-not $NoStart) {
                Write-VerboseMark -Message "Starting service: Start-Service 'FirebirdServer$Name'"
                Start-Service -Name "FirebirdServer$Name"
            } else {
                Write-VerboseMark -Message 'Skipping service start (-NoStart specified).'
            }
        }

        $svc = Get-Service -Name "FirebirdServer$Name" -ErrorAction SilentlyContinue
        $status = if ($svc) { $svc.Status.ToString() } else { 'Unknown' }
    } elseif ($IsLinux) {
        Write-VerboseMark -Message 'Registering systemd service'
        $unitName = $Name.ToLower()
        $unitPath = "/etc/systemd/system/$($unitName).service"

        if (Test-Path $unitPath) {
            throw "A systemd unit file already exists at '$unitPath'. Remove it first with Remove-FirebirdService."
        }

        # Configure the listening port in firebird.conf
        Write-VerboseMark -Message "Setting RemoteServicePort to $Port in $firebirdConfPath"
        Write-FirebirdConfiguration -Path $firebirdConfPath -Configuration @{ RemoteServicePort = $Port }

        $serverPath = $Environment.GetServerPath()
        $envPath = (Resolve-Path $Environment.Path).Path

        $unitContent = @"
[Unit]
Description=Firebird $($Environment.Version) Database Server ($Name)
After=network.target

[Service]
Type=simple
ExecStart=$serverPath -p $Port
WorkingDirectory=$envPath
Environment="FIREBIRD=$envPath" "LD_LIBRARY_PATH=$envPath/lib"
Restart=on-failure

[Install]
WantedBy=multi-user.target
"@

        if ($PSCmdlet.ShouldProcess($unitPath, 'Create systemd unit file')) {
            Write-VerboseMark -Message "Writing systemd unit file: $unitPath"
            Set-Content -Path $unitPath -Value $unitContent

            Write-VerboseMark -Message 'Running: systemctl daemon-reload'
            Invoke-ExternalCommand { & systemctl daemon-reload } `
                -ErrorMessage 'Failed to reload systemd daemon'

            Write-VerboseMark -Message "Running: systemctl enable $unitName"
            Invoke-ExternalCommand { & systemctl enable $unitName } `
                -ErrorMessage "Failed to enable service '$unitName'"

            if (-not $NoStart) {
                Write-VerboseMark -Message "Running: systemctl start $unitName"
                Invoke-ExternalCommand { & systemctl start $unitName } `
                    -ErrorMessage "Failed to start service '$unitName'"
            } else {
                Write-VerboseMark -Message 'Skipping service start (-NoStart specified).'
            }
        }

        $null = & systemctl is-active $unitName 2>&1
        $status = if ($LASTEXITCODE -eq 0) { 'Running' } else { 'Stopped' }
    } else {
        throw 'Unsupported platform. Only Windows and Linux are supported.'
    }

    [PSCustomObject]@{
        Name            = $Name
        Port            = $Port
        EnvironmentPath = $Environment.Path
        Status          = $status
    }
}
