function Start-FirebirdInstance {
    <#
    .SYNOPSIS
        Starts a Firebird server process from the specified environment.
    .DESCRIPTION
        Launches the Firebird server executable with the given port using Start-Process. Returns the process object.
    .PARAMETER Port
        The port to listen on. Defaults to 3050 if not specified.
    .PARAMETER Environment
        The Firebird environment to use. Uses the current environment if not specified.
    .EXAMPLE
        Start-FirebirdInstance -Port 3051 -Environment $fbEnv
        Starts the Firebird server on port 3051 from the specified environment.
    #>
    [CmdletBinding()]
    param(
        [int]$Port = 3050,
        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default()
    )

    $serverPath = $Environment.GetServerPath()

    $arguments = @('-p', $Port)
    if ($IsWindows) {
        $arguments += '-a'        
    }

    Write-VerboseMark -Message "Starting Firebird server: $serverPath $arguments"
    $process = Start-Process -FilePath $serverPath -ArgumentList $arguments -PassThru

    # Return the instance information.
    [FirebirdInstance]::new(@{
            Environment = $Environment
            Process     = $process

            Port        = $Port
        })
}
