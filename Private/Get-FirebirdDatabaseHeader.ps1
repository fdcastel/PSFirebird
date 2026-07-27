function Get-FirebirdDatabaseHeader {
    <#
    .SYNOPSIS
        Parses PageSize and ODSVersion from gstat -h output.
    .PARAMETER Database
        The Firebird database to inspect.
    .PARAMETER Environment
        The Firebird environment to use.
    .OUTPUTS
        Hashtable with PageSize and ODSVersion keys.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [FirebirdDatabase]$Database,

        [Parameter(Mandatory)]
        [FirebirdEnvironment]$Environment
    )

    $connectionString = $Database.ConnectionString()
    $gstat = $Environment.GetGstatPath()
    Write-VerboseMark -Message "Reading database header from '$connectionString'."

    $gstatResult = Invoke-ExternalCommand {
        & $gstat -h $connectionString
    } -Passthru -ErrorMessage 'Error running gstat.'

    # Both patterns are anchored to the leading whitespace of a header field, so the
    # preamble ("Database ...", "Gstat execution time ...") cannot match and there is no
    # need to skip a fixed number of lines.
    $pageSize = $null
    $odsVersion = $null
    foreach ($line in $gstatResult.StdOut) {
        if ($line -match '^\s+Page size\s+(\d+)') {
            $pageSize = [int]$Matches[1].Trim()
            Write-VerboseMark -Message "Parsed Page size: $($pageSize)"
        }

        if ($line -match '^\s+ODS Version\s+([\d]+\.[\d]+)') {
            $odsVersion = [version]$Matches[1].Trim()
            Write-VerboseMark -Message "Parsed ODS Version: $($odsVersion)"
            break
        }
    }

    if ($null -eq $odsVersion) {
        Write-VerboseMark -Message 'gstat output contained no ODS Version field.'
    }

    @{
        PageSize   = $pageSize
        ODSVersion = $odsVersion
    }
}
