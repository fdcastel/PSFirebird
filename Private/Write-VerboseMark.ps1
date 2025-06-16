function Write-VerboseMark {
    <#
    .SYNOPSIS
        Writes a verbose message with script name and line number for context.
    .PARAMETER Message
        The message to display in verbose output.
    .EXAMPLE
        Write-VerboseMark -Message "Starting process."
        Displays a verbose message with script and line information.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )
    Write-Verbose "$Message  [$($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)]"
}
