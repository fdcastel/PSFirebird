<#
.SYNOPSIS
Gets the ODS (On-Disk Structure) version of a Firebird database file.

.DESCRIPTION
Reads the header of a Firebird database file and returns its ODS major and minor version as a version object.

.PARAMETER DatabasePath
Path to the Firebird database file to inspect. Must exist.

.EXAMPLE
Get-FirebirdODSVersion -DatabasePath '/data/mydb.fdb'
Returns the ODS version of the specified database file.

.OUTPUTS
System.Version. The ODS version in the format Major.Minor.
#>
function Get-FirebirdODSVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'The DatabasePath must exist.')]
        [string]$DatabasePath
    )

    # Read the first 80 bytes of the database file
    Write-VerboseMark "Reading header from file '$DatabasePath'..."
    $bytes = Get-Content -Path $DatabasePath -AsByteStream -TotalCount 80
    if ($bytes.Length -lt 80) {
        throw "File '$DatabasePath' is not a valid Firebird database."
    }

    # Source: https://www.firebirdsql.org/file/documentation/html/en/firebirddocs/firebirdinternals/firebird-internals.html

    # hdr_ods_version
    #   Two bytes, unsigned. Bytes 0x12 and 0x13 on the page. The ODS major version for the database. 
    #   The format of this word is the ODS major version ANDed with the Firebird flag of 0x8000.
    $odsVersion = [BitConverter]::ToUInt16($bytes, 0x12) -band 0x7FFF
    Write-VerboseMark "odsVersion = $($odsVersion)"

    # hdr_ods_minor_original
    #   Two bytes, unsigned. Bytes 0x40 and 0x41 on the page. The ODS minor version when the database was originally created.
    $odsMinorOriginal = [BitConverter]::ToUInt16($bytes, 0x40)
    Write-VerboseMark "odsMinorOriginal = $($odsMinorOriginal)"

    # Return as [version] object
    return [version]::new($odsVersion, $odsMinorOriginal)
}
