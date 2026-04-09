# Resolve the Firebird version for integration tests.
# Uses FIREBIRD_VERSION env var if set, otherwise falls back to the module default.
$script:FirebirdVersion = if ($env:FIREBIRD_VERSION) {
    $env:FIREBIRD_VERSION
} else {
    (Import-PowerShellDataFile "$PSScriptRoot/../PSFirebird.psd1").PrivateData.DefaultFirebirdVersion
}

# Optional RuntimeIdentifier override for integration tests.
# When set, tests pass -RuntimeIdentifier to New-FirebirdEnvironment (e.g. 'win-x86', 'win-arm64').
# When empty, the function auto-detects the RID from the current platform.
# On Windows ARM64 with no explicit RID, fall back to win-x64 (x64 emulation) because
# Firebird does not yet publish Windows ARM64 binaries.
$script:FirebirdExtraParams = @{}
if ($env:FIREBIRD_RID) {
    $script:FirebirdExtraParams['RuntimeIdentifier'] = $env:FIREBIRD_RID
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier -eq 'win-arm64') {
    $script:FirebirdExtraParams['RuntimeIdentifier'] = 'win-x64'
}
