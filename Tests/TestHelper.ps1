# Resolve the Firebird target for integration tests.
# Uses FIREBIRD_BRANCH env var for snapshot builds (e.g. 'master' for v6),
# or FIREBIRD_VERSION env var for official releases (e.g. '5.0.3'),
# falling back to the module default version.
$script:FirebirdBranch = $env:FIREBIRD_BRANCH
$script:FirebirdVersion = if ($FirebirdBranch) {
    "snapshot-$FirebirdBranch"
} elseif ($env:FIREBIRD_VERSION) {
    $env:FIREBIRD_VERSION
} else {
    (Import-PowerShellDataFile "$PSScriptRoot/../PSFirebird.psd1").PrivateData.DefaultFirebirdVersion
}

# Build the primary parameters for New-FirebirdEnvironment.
# Contains either -Branch (snapshots) or -Version (official releases).
$script:FirebirdEnvParams = @{}
if ($FirebirdBranch) {
    $script:FirebirdEnvParams['Branch'] = $FirebirdBranch
} else {
    $script:FirebirdEnvParams['Version'] = $FirebirdVersion
}

# Optional RuntimeIdentifier override for integration tests.
# When set, tests pass -RuntimeIdentifier to New-FirebirdEnvironment (e.g. 'win-x86', 'win-arm64').
# When empty, the function auto-detects the RID from the current platform.
# New-FirebirdEnvironment itself handles win-arm64 → win-x64 fallback for official releases.
$script:FirebirdExtraParams = @{}
if ($env:FIREBIRD_RID) {
    $script:FirebirdExtraParams['RuntimeIdentifier'] = $env:FIREBIRD_RID
}
