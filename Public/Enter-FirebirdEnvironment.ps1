<#
.SYNOPSIS
Sets and enters a Firebird environment for the current session.

.DESCRIPTION
Use this function to set the current Firebird environment by specifying a path or an environment object.

.PARAMETER Path
The path to a Firebird environment. Use this to enter an environment by its location.

.PARAMETER Environment
A FirebirdEnvironment object. Use this to enter an environment you already have.

.EXAMPLE
Enter-FirebirdEnvironment -Path 'C:/Firebird/env1'

.EXAMPLE
Enter-FirebirdEnvironment -Environment $envObj

.EXAMPLE
Get-FirebirdEnvironment -Path 'C:/Firebird/env1' | Enter-FirebirdEnvironment

.OUTPUTS
FirebirdEnvironment. Returns the current Firebird environment object.
#>
function Enter-FirebirdEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'ByPath', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Path must be a valid path.')]
        [string]$Path,

        [Parameter(Position = 0, ParameterSetName = 'ByEnvironment', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $Environment
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByPath' {
                Write-VerboseMark 'Entering Firebird environment by path.'
                $envResult = Get-FirebirdEnvironment -Path $Path
            }
            'ByEnvironment' {
                Write-VerboseMark 'Entering Firebird environment by environment object.'
                $envResult = Get-FirebirdEnvironment -Environment $Environment
            }
        }
        $script:CurrentFirebirdEnvironment = $envResult
        Write-VerboseMark 'CurrentFirebirdEnvironment set.'
        return $script:CurrentFirebirdEnvironment
    }
}
