@{
    # Module manifest for PSFirebird

    # Version number of this module.
    ModuleVersion     = '0.0.0'

    # ID used to uniquely identify this module
    GUID              = '8539f3ce-d536-4e1a-926d-7243a83a9b93'

    # Author of this module
    Author            = 'F.D.Castel'

    # Company or vendor of this module
    CompanyName       = ''

    # Copyright statement for this module
    Copyright         = '(c) F.D.Castel. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'PowerShell toolkit for Firebird databases.'

    FunctionsToExport = @(
        'Backup-FirebirdDatabase',
        'Convert-FirebirdDatabase',
        
        'Get-FirebirdDatabase',
        'Get-FirebirdEnvironment',
        'Get-FirebirdInstance',

        'Invoke-FirebirdIsql',
        'Lock-FirebirdDatabase',

        'New-FirebirdDatabase',
        'New-FirebirdEnvironment',

        'Read-FirebirdConfiguration',
        'Read-FirebirdDatabase',

        'Remove-FirebirdDatabase',

        'Remove-FirebirdEnvironment',

        'Restore-FirebirdDatabase',

        'Start-FirebirdInstance',
        'Stop-FirebirdInstance',

        'Test-FirebirdDatabase',

        'Use-FirebirdEnvironment',

        'Unlock-FirebirdDatabase',
        
        'Write-FirebirdConfiguration'
    )

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.4'



    # Script module or binary module file associated with this manifest.
    RootModule        = 'PSFirebird.psm1' # Or ModuleToProcess for older PowerShell versions



    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata.
    PrivateData       = @{
        # Default Firebird version used by integration tests when FIREBIRD_VERSION env var is not set.
        DefaultFirebirdVersion = '5.0.3'

        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('firebird', 'database', 'administration', 'admin')

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/fdcastel/PSFirebird'

            # A URL to an icon representing this module.
            IconUri      = 'https://cdn.jsdelivr.net/gh/fdcastel/PSFirebird@master/docs/PSFirebird-logo-256.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/fdcastel/PSFirebird/releases'
        }
    }
}
