function Write-VerboseMark {
    <#
    .SYNOPSIS
        Writes a verbose message with script name and line number for context.

    .DESCRIPTION
        This function writes a verbose message that includes the script name and line number where the message was generated. 
        In modern editors like Visual Studio Code, this provides a quick link to the code when analyzing execution output.

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
