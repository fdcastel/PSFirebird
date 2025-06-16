function Get-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Returns information about a Firebird environment at the specified path.
    .PARAMETER Path
        The path to the Firebird environment directory.
    .PARAMETER Environment
        An object representing a Firebird environment. Its Path property will be used.
    .OUTPUTS
        FirebirdEnvironment with Path and Version properties.
    .EXAMPLE
        Get-FirebirdEnvironment -Path '/opt/firebird-5.0.2'
        Returns environment info for the specified path.
    .EXAMPLE
        Get-FirebirdEnvironment -Environment $envObj
        Returns environment info using the provided environment object.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Path must be a valid path.')]
        [string]$Path,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Environment')]
        [FirebirdEnvironment]$Environment
    )

    if ($Environment) {
        $Path = $Environment.Path
    }

    if (-not $Path) {
        throw 'Automatic environment detection is not implemented yet.'
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
