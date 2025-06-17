<#
.SYNOPSIS
    Sets the current Firebird environment for the session.
.DESCRIPTION
    Sets or switches the Firebird environment used by other cmdlets in the session.
.PARAMETER Environment
    A FirebirdEnvironment object to set as the current environment.
.EXAMPLE
    Use-FirebirdEnvironment -Environment $envObj
    Sets the current environment to the provided object.
.EXAMPLE
    Get-FirebirdEnvironment -Path 'C:/Firebird/env1' | Use-FirebirdEnvironment
    Sets the current environment using the specified path.
.OUTPUTS
    FirebirdEnvironment. Returns the current Firebird environment object.
#>
function Use-FirebirdEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [FirebirdEnvironment]$Environment
    )

    process {
        Write-VerboseMark "Entering Firebird environment: $Environment"
        $script:CurrentFirebirdEnvironment = $Environment

        return $script:CurrentFirebirdEnvironment
    }
}
