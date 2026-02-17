# Resolve the Firebird version for integration tests.
# Uses FIREBIRD_VERSION env var if set, otherwise falls back to the module default.
$script:FirebirdVersion = if ($env:FIREBIRD_VERSION) {
    $env:FIREBIRD_VERSION
} else {
    (Import-PowerShellDataFile "$PSScriptRoot/../PSFirebird.psd1").PrivateData.DefaultFirebirdVersion
}
