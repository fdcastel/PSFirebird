function New-FirebirdDatabase {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$DatabasePath,

        [Parameter(Mandatory = $false)]
        [string]$User = 'SYSDBA',

        [Parameter(Mandatory = $false)]
        [string]$Password = 'masterkey',

        [Parameter(Mandatory = $false)]
        [ValidateSet(4096, 8192, 16384, 32768)]
        [int]$PageSize = 8192,

        [Parameter(Mandatory = $false)]
        [string]$Charset = 'UTF8',

        [Parameter(Mandatory = $false)]
        [string]$EnvironmentPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if (-not $EnvironmentPath) {
        Write-VerboseMark -Message 'EnvironmentPath not specified. Detecting using Get-FirebirdEnvironment.'
        $envInfo = Get-FirebirdEnvironment
        $EnvironmentPath = $envInfo.Path
    }

    Write-VerboseMark -Message "Using Firebird environment at '$($EnvironmentPath)'"

    $isql = if ($IsWindows) { 
        Join-Path $EnvironmentPath 'isql.exe'
    } else {
        Join-Path $EnvironmentPath 'bin/isql'
    }
    if (-not (Test-Path $isql -PathType Leaf)) {
        throw "isql not found at '$($isql)'"
    }

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
        DatabasePath = $DatabasePath
        PageSize     = $PageSize
        Charset      = $Charset
        User         = $User
    }
}
