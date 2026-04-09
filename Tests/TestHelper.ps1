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
$script:FirebirdExtraParams = @{}
if ($env:FIREBIRD_RID) {
    $script:FirebirdExtraParams['RuntimeIdentifier'] = $env:FIREBIRD_RID
}
