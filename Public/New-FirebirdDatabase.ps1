function New-FirebirdDatabase {
    <#
    .SYNOPSIS
        Creates a new Firebird database at the specified path.
    .PARAMETER DatabasePath
        The file path for the new database. Must not already exist unless -Force is used.
    .PARAMETER User
        The database user name. Defaults to 'SYSDBA'.
    .PARAMETER Password
        The database user password. Defaults to 'masterkey'.
    .PARAMETER PageSize
        The page size for the database. Allowed values: 4096, 8192, 16384, 32768. Default is 8192.
    .PARAMETER Charset
        The character set for the database. Defaults to 'UTF8'.
    .PARAMETER Environment
        The Firebird environment object to use for database creation.
    .PARAMETER Force
        Overwrites the database file if it already exists.
    .OUTPUTS
        PSCustomObject with DatabasePath, PageSize, Charset, and User properties.
    .EXAMPLE
        New-FirebirdDatabase -DatabasePath '/tmp/test.fdb' -Force
        Creates a new database at the specified path, overwriting if it exists.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$DatabasePath,

        [string]$User = 'SYSDBA',

        [string]$Password = 'masterkey',

        [ValidateSet(4096, 8192, 16384, 32768)]
        [int]$PageSize = 8192,

        [string]$Charset = 'UTF8',

        [FirebirdEnvironment]$Environment,

        [switch]$Force
    )

    if (-not $Environment) {
        $Environment = Get-FirebirdEnvironment
    }
    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    if (Test-Path -Path $DatabasePath -PathType Leaf) {
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($DatabasePath, 'Remove existing database file')) {
                Write-VerboseMark -Message "Database file '$($DatabasePath)' already exists and -Force specified. Removing database file..."
                Remove-Item -Path $DatabasePath -Force
            }
        } else {
            throw "Database file '$($DatabasePath)' already exists. Use -Force to overwrite."
        }
    }

    if ($PSCmdlet.ShouldProcess($DatabasePath, 'Create new Firebird database')) {
        $createDbCmd = @"
CREATE DATABASE '$DatabasePath' 
    USER '$User' 
    PASSWORD '$Password' 
    PAGE_SIZE $PageSize 
    DEFAULT CHARACTER SET $Charset;
"@

        $isql = $Environment.GetIsqlPath()
        
        Write-VerboseMark -Message "Creating database at '$($DatabasePath)' with user '$($User)', page size $($PageSize), charset '$($Charset)'."
        $output = $createDbCmd | & $isql -quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            # Split StdOut and StdErr -- https://stackoverflow.com/a/68106198/33244
            $stdOut, $stdErr = $output.Where({ $_ -is [string] }, 'Split')
            throw $stdErr
        }

        Write-VerboseMark -Message "Database created successfully at '$($DatabasePath)'"
    }
    [PSCustomObject]@{
        Environment  = $Environment
        DatabasePath = $DatabasePath

        PageSize     = $PageSize
        Charset      = $Charset
        User         = $User
    }
}
