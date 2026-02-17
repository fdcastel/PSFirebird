function Get-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Retrieves information about a Firebird environment at a given path or from an environment object.
    .DESCRIPTION
        Returns a FirebirdEnvironment object with details about the specified or current environment.
    .PARAMETER Path
        Path to the Firebird environment directory. Optional if an environment object is provided.
    .EXAMPLE
        Get-FirebirdEnvironment -Path '/opt/firebird-5.0.2'
        Returns environment info for the specified path.
    .OUTPUTS
        FirebirdEnvironment object with Path and Version properties.
    #>

    [CmdletBinding()]
    [OutputType([FirebirdEnvironment])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Path must be a valid path.')]
        [string]$Path
    )

    $Path = Resolve-Path $Path
    Write-VerboseMark -Message "Checking Firebird environment at '$($Path)'."

    # Determine the environment version from gstat header.
    $gstat = if ($global:IsWindows) { 
        Join-Path $Path 'gstat.exe'
    } else {
        Join-Path $Path 'bin/gstat'
    }
    $gstatResult = Invoke-ExternalCommand {
        & $gstat -z
    } -SuccessExitCodes @(0,1) -Passthru -ErrorMessage 'Failed to run gstat command. Cannot determine Firebird version.'

    $version = $null
    if ($gstatResult.StdOut[0] -match '\-V(\d+\.\d+\.\d+\.\d+)') {
        $version = $matches[1]
    } else {
        throw "Cannot determine Firebird version. Unexpected gstat output: $($gstatResult.StdOut)"
    }

    # Return the environment information as a FirebirdEnvironment class instance.
    [FirebirdEnvironment]::new(@{
            Path    = $Path
            Version = [version]$version
        })
}
