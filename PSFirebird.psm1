# PSFirebird Root Module Script

$ErrorActionPreference = 'Stop'

# Import all public/private function files from Functions subfolders
$Public = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public/*.ps1') -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private/*.ps1') -ErrorAction SilentlyContinue)

# Dot source the functions
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing function from $($import.FullName)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Define the FirebirdEnvironment type
Write-Verbose "Updating FirebirdEnvironment TypeData..."
Remove-TypeData -TypeName FirebirdEnvironment -ErrorAction SilentlyContinue
$TypeData = @{
    TypeName = 'FirebirdEnvironment'

    MemberType = 'ScriptProperty'
    MemberName = 'DisplayName'
    Value = {"Firebird $($this.Version) at $($this.Path)"}

    DefaultDisplayPropertySet = 'DisplayName'
}
Update-TypeData @TypeData

Write-Verbose 'PSFirebird module loaded.'
