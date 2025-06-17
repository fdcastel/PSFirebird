function Get-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Retrieves information about a Firebird environment at a given path or from an environment object.
    .DESCRIPTION
        Returns a FirebirdEnvironment object with details about the specified or current environment.
    .PARAMETER Path
        Path to the Firebird environment directory. Optional if an environment object is provided.
    .PARAMETER Environment
        A FirebirdEnvironment object. Its Path property will be used.
    .EXAMPLE
        Get-FirebirdEnvironment -Path '/opt/firebird-5.0.2'
        Returns environment info for the specified path.
    .EXAMPLE
        Get-FirebirdEnvironment -Environment $envObj
        Returns environment info using the provided environment object.
    .OUTPUTS
        FirebirdEnvironment object with Path and Version properties.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'ByPath')]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Path must be a valid path.')]
        [string]$Path,

        [Parameter(Position = 0, Mandatory, ParameterSetName = 'ByEnvironment')]
        [FirebirdEnvironment]$Environment
    )

    if ($Environment) {
        $Path = $Environment.Path
    }

    if (-not $Path) {
        if ($CurrentFirebirdEnvironment) {
            # Use the current environment if available.
            $Path = $CurrentFirebirdEnvironment.Path
        } else {
            # No path is provided nor current environment is set. Cannot proceed.
            throw 'There is currently no Firebird environment set. Please provide a -Path or use Use-FirebirdEnvironment.'
        }
    }

    $Path = Resolve-Path $Path
    Write-VerboseMark -Message "Checking Firebird environment at '$($Path)'."

    $productVersion = $null
    try {
        if ($IsWindows) {
            # Windows: Determine the version from VERSIONINFO resource in firebird.exe.

            $firebirdBinary = Join-Path -Path $Path -ChildPath 'firebird.exe'
            if (-not (Test-Path -Path $firebirdBinary -PathType Leaf)) {
                throw "$firebirdBinary not found at $($firebirdBinary)"
            }

            try {
                $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($firebirdBinary)
                $productVersion = $versionInfo.ProductVersion
                Write-VerboseMark -Message "Extracted ProductVersion: '$($productVersion)' from '$($firebirdBinary)'."
            } catch {
                throw "Failed to extract ProductVersion from $($firebirdBinary): $($_.Exception.Message)"
                $null
            }
        } else {
            # Linux: There are no version in ELF64 binaries.
            # Determine the version looking for "./opt/firebird/lib/libfbclient.so.<version>" in manifest.txt

            $manifestPath = Join-Path -Path $Path -ChildPath 'manifest.txt'
            if (-not (Test-Path -Path $manifestPath -PathType Leaf)) {
                throw "Manifest file not found at $($manifestPath)"
            }

            $manifestContent = Get-Content -Path $manifestPath -Raw
            $versionMatch = $manifestContent -match '\./opt/firebird/lib/libfbclient\.so\.(\d+\.\d+\.\d+)'
            if (-not $versionMatch) {
                throw "Pattern to extract version from manifest at $($manifestPath) not found."
            }

            $productVersion = $matches[1]
            Write-VerboseMark -Message "Extracted ProductVersion: '$($productVersion)' from manifest at '$($manifestPath)'."
        }
    } catch {
        Write-Warning -Message "Cannot extract ProductVersion from $($firebirdBinary): $($_.Exception.Message)"
    }

    # Return the environment information as a FirebirdEnvironment class instance.
    [FirebirdEnvironment]::new(@{
            Path    = $Path
            Version = [version]$productVersion
        })
}
