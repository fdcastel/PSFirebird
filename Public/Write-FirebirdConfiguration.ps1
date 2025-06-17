function Write-FirebirdConfiguration {
    <#
    .SYNOPSIS
    Updates configuration values in a Firebird config file using a hashtable.

    .DESCRIPTION
    Modifies, adds, or comments out configuration entries in the file based on the hashtable provided.
    Existing keys are updated or uncommented. Missing keys are appended. Null values comment out the key.

    .PARAMETER Path
    The path to the Firebird configuration file to update.

    .PARAMETER Configuration
    Hashtable of key/value pairs to write. Use $null as value to comment out a key.

    .EXAMPLE
    Write-FirebirdConfiguration -Path 'C:/Firebird/firebird.conf' -Configuration @{ 'Key' = 'Value' }
    Updates or adds the specified key/value in the configuration file.

    .EXAMPLE
    Write-FirebirdConfiguration -Path 'C:/Firebird/firebird.conf' -Configuration @{ 'Key' = $null }
    Comments out the specified key in the configuration file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable]$Configuration
    )
    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }
    $lines = Get-Content -Path $Path
    $keys = $Configuration.Keys
    $updated = @{}
    $output = @()
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        $matched = $false
        foreach ($key in $keys) {
            $pattern = "^(#)?$($key)\s*=.*$"
            if ($trimmed -match $pattern) {
                $matched = $true
                $value = $Configuration[$key]
                if ($null -eq $value) {
                    $output += "#$($key) = "
                    Write-VerboseMark -Message "Commented out $key as value is null."
                } else {
                    $output += "$($key) = $($value)"
                    Write-VerboseMark -Message "Updated $key to $value."
                }
                $updated[$key] = $true
                break
            }
        }
        if (-not $matched) {
            $output += $line
        }
    }
    foreach ($key in $keys) {
        if (-not $updated.ContainsKey($key)) {
            $value = $Configuration[$key]
            if ($null -eq $value) {
                $output += "#$($key) = "
                Write-VerboseMark "Key '$key' not found in file. Appending as commented out."
            } else {
                $output += "$($key) = $($value)"
                Write-VerboseMark "Key '$key' not found in file. Appending at end."
            }
            Write-VerboseMark -Message "Appended $key to file."
        }
    }
    Set-Content -Path $Path -Value $output
}
