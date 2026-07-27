# Shared configuration and fixtures for the integration test suites.
#
# Everything here is declared in the global scope on purpose. Pester v5 runs
# BeforeAll/It blocks in a scope that does not chain to the scope this file is dot-sourced
# into, so file-scoped functions are not visible there. Unqualified reads from test files
# still resolve, since global is the last link in the scope chain.

# Resolve the Firebird target for integration tests.
# Uses FIREBIRD_BRANCH env var for snapshot builds (e.g. 'master' for v6),
# or FIREBIRD_VERSION env var for official releases (e.g. '5.0.3'),
# falling back to the module default version.
$global:FirebirdBranch = $env:FIREBIRD_BRANCH
$global:FirebirdVersion = if ($FirebirdBranch) {
    "snapshot-$FirebirdBranch"
} elseif ($env:FIREBIRD_VERSION) {
    $env:FIREBIRD_VERSION
} else {
    (Import-PowerShellDataFile "$PSScriptRoot/../PSFirebird.psd1").PrivateData.DefaultFirebirdVersion
}

# Build the primary parameters for New-FirebirdEnvironment.
# Contains either -Branch (snapshots) or -Version (official releases).
$global:FirebirdEnvParams = @{}
if ($FirebirdBranch) {
    $global:FirebirdEnvParams['Branch'] = $FirebirdBranch
} else {
    $global:FirebirdEnvParams['Version'] = $FirebirdVersion
}

# Optional RuntimeIdentifier override for integration tests.
# When set, tests pass -RuntimeIdentifier to New-FirebirdEnvironment (e.g. 'win-x86', 'win-arm64').
# When empty, the function auto-detects the RID from the current platform.
# New-FirebirdEnvironment itself handles win-arm64 → win-x64 fallback for official releases.
$global:FirebirdExtraParams = @{}
if ($env:FIREBIRD_RID) {
    $global:FirebirdExtraParams['RuntimeIdentifier'] = $env:FIREBIRD_RID
}


function global:New-TestFixture {
    <#
    .SYNOPSIS
        Creates the temp folder, Firebird environment and test database an integration
        suite needs, and sets the credentials its tools authenticate with.
    .PARAMETER DatabaseName
        File name for the test database inside the temp folder. Defaults to a name derived
        from the Firebird version under test.
    .PARAMETER NoDatabase
        Create the environment only, without a database.
    .OUTPUTS
        PSCustomObject with RootFolder, Environment and Database properties, plus the
        ISC_USER/ISC_PASSWORD values captured before they were overwritten so that
        Remove-TestFixture can put them back.
    #>
    param(
        [string]$DatabaseName,

        [switch]$NoDatabase
    )

    if (-not $DatabaseName) {
        $DatabaseName = "$($global:FirebirdVersion)-tests.fdb"
    }

    $rootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)
    $environment = New-FirebirdEnvironment @global:FirebirdEnvParams @global:FirebirdExtraParams

    # Capture before overwriting: these are process-wide and would otherwise leak into
    # whatever runs after this suite.
    $originalUser = $env:ISC_USER
    $originalPassword = $env:ISC_PASSWORD
    $env:ISC_USER = 'SYSDBA'
    $env:ISC_PASSWORD = 'masterkey'

    $database = if ($NoDatabase) {
        $null
    } else {
        New-FirebirdDatabase -Database "$rootFolder/$DatabaseName" -Environment $environment
    }

    return [PSCustomObject]@{
        RootFolder       = $rootFolder
        Environment      = $environment
        Database         = $database
        OriginalUser     = $originalUser
        OriginalPassword = $originalPassword
    }
}

function global:Remove-TestFixture {
    <#
    .SYNOPSIS
        Removes a fixture's temp folder and restores the previous Firebird credentials.
    .PARAMETER Fixture
        The object returned by New-TestFixture.
    #>
    param(
        [Parameter(Mandatory)]
        $Fixture
    )

    if ($Fixture.RootFolder) {
        Remove-Item -Path $Fixture.RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($pair in @(@('ISC_USER', $Fixture.OriginalUser), @('ISC_PASSWORD', $Fixture.OriginalPassword))) {
        if ([string]::IsNullOrEmpty($pair[1])) {
            Remove-Item "env:$($pair[0])" -ErrorAction SilentlyContinue
        } else {
            Set-Item "env:$($pair[0])" -Value $pair[1]
        }
    }
}
