<#
.SYNOPSIS
Clears the current Firebird environment for the session.

.DESCRIPTION
Use this function to exit and clear the active Firebird environment from the session.

.EXAMPLE
Exit-FirebirdEnvironment

.OUTPUTS
None. The current Firebird environment is removed.
#>
function Exit-FirebirdEnvironment {
    [CmdletBinding()]

    $script:CurrentFirebirdEnvironment = $null
    Write-VerboseMark 'CurrentFirebirdEnvironment cleared.'
}
