function Get-FirebirdInstance {
    <#
    .SYNOPSIS
        Retrieves information about running Firebird server processes.
    .DESCRIPTION
        Returns information about all running Firebird processes including process ID, path, version, command line, start time, and port number.
    .EXAMPLE
        Get-FirebirdInstance
        Returns details for all running Firebird server processes.
    .EXAMPLE
        Get-FirebirdInstance | Stop-FirebirdInstance
        Stops all running Firebird instances.
    .OUTPUTS
        PSCustomObject with Id, Path, ProductVersion, CommandLine, StartTime, and Port properties.
    #>

    [CmdletBinding()]
    param()

    Write-VerboseMark -Message 'Retrieving running Firebird instances'

    Get-Process 'firebird' -ErrorAction SilentlyContinue |
        Select-Object 'Id', 'Path', 'ProductVersion', 'CommandLine', 'StartTime', @{Name = 'Port'; Expression = { if ($_.CommandLine -Match '-p\s+(\d+)') { $Matches[1] } } }
}
