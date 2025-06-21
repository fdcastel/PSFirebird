function Use-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Executes a script block within a Firebird environment context.
    .DESCRIPTION
        Sets a Firebird environment context for the duration of the script block execution.
    .PARAMETER Environment
        A FirebirdEnvironment object to set as the context environment.
    .PARAMETER ScriptBlock
        The script block to execute within the environment context.
    .EXAMPLE
        Use-FirebirdEnvironment -Environment $fbEnv {
            New-FirebirdDatabase -Database 'test.fdb'
            Backup-FirebirdDatabase -Database 'test.fdb' -BackupFilePath 'backup.fbk'
        }

        Executes the commands using the specified environment context.
    .EXAMPLE
        Get-FirebirdEnvironment -Path 'C:/Firebird' | Use-FirebirdEnvironment -ScriptBlock {
            New-FirebirdDatabase -Database 'test.fdb'
        }

        Uses pipeline input to set the environment context.
    .OUTPUTS
        Returns the result of the script block execution.
    .NOTES
        You must use the -ScriptBlock parameter name explicitly when using the pipeline.
        This is a PowerShell parameter binding limitation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [FirebirdEnvironment]$Environment,

        [Parameter(Position = 1, Mandatory)]
        [scriptblock]$ScriptBlock
    )

    process {
        # Store the current context
        $previousContext = Get-Variable -Name 'FirebirdEnvironment' -Scope 1 -ValueOnly -ErrorAction SilentlyContinue
        try {
            # Set the environment context in the caller's scope
            Set-Variable -Name 'FirebirdEnvironment' -Value $Environment -Scope 1 -Force
            
            # Execute the script block and return its result
            & $ScriptBlock
        }
        finally {
            if ($null -ne $previousContext) {
                # Restore the previous context
                Set-Variable -Name 'FirebirdEnvironment' -Value $previousContext -Scope 1 -Force
            } else {
                # Remove the context variable entirely
                Remove-Variable -Name 'FirebirdEnvironment' -Scope 1 -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
