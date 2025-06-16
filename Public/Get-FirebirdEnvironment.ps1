function Get-FirebirdEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Path must be a valid path.')]
        [string]$Path,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Environment')]
        [PSTypeName('FirebirdEnvironment')]$Environment
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
            Join-Path -Path $Path -ChildPath 'firebird.exe'
            if (-not (Test-Path -Path $firebirdBinary -PathType Leaf)) {
                throw "$firebirdBinary not found at $($firebirdBinary)"
            }

            try {
                $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($firebirdBinary)
                $productVersion = $versionInfo.ProductVersion
                Write-VerboseMark -Message "Extracted ProductVersion: '$($productVersion)' from binary at '$($firebirdBinary)'."
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

    # Return the environment information as a PSCustomObject
    [PSCustomObject]@{
        PSTypeName = 'FirebirdEnvironment'
        Path       = $Path
        Version    = [version]$productVersion
    }
}
