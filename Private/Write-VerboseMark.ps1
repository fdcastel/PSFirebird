function Write-VerboseMark {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )
    Write-Verbose "$Message  [$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)]"
}
