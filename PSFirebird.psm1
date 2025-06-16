# PSFirebird Root Module Script

$ErrorActionPreference = 'Stop'

# Import types
$Types = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Types/*.ps1') -ErrorAction SilentlyContinue)
foreach ($import in $Types) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import $($import.FullName): $_"
    }
}



#
# Exporting classes with type accelerators 
#   https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators
#

# Define the types to export with type accelerators.
$ExportableTypes = @(
    [FirebirdEnvironment]
)
# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)
# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
foreach ($Type in $ExportableTypes) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        $Message = @(
            "Unable to register type accelerator '$($Type.FullName)'"
            'Accelerator already exists.'
        ) -join ' - '

        throw [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            'TypeAcceleratorAlreadyExists',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Type.FullName
        )
    }
}
# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()


# Shared private variables

[FirebirdEnvironment]$script:CurrentFirebirdEnvironment = $null


# Import all public/private function files from Functions subfolders
$Public = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public/*.ps1') -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private/*.ps1') -ErrorAction SilentlyContinue)
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
