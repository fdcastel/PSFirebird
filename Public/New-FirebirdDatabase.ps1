function New-FirebirdDatabase {
    <#
    .SYNOPSIS
        Creates a new Firebird database at the specified path.
    .DESCRIPTION
        Generates a new Firebird database file with the given options and returns its details.
    .PARAMETER Database
        Full path and file name including its extension. Must not exist unless -Force is used.
    .PARAMETER Credential
        PSCredential for the database owner. Takes precedence over -User and -Password if specified.
    .PARAMETER User
        Username of the owner of the new database. Defaults to 'SYSDBA'.
    .PARAMETER Password
        Password of the user as the database owner. Defaults to 'masterkey'.
    .PARAMETER PageSize
        Page size for the database. Allowed: 4096, 8192, 16384, 32768. Default is 8192.
    .PARAMETER Charset
        The default character set for string data types. Defaults to 'UTF8'.
    .PARAMETER Environment
        Firebird environment object to use for database creation.
    .PARAMETER Force
        Overwrites the database file if it already exists.
    .EXAMPLE
        New-FirebirdDatabase -Database '/tmp/test.fdb' -Force
        Creates a new database at the specified path, overwriting if it exists.
    .EXAMPLE
        New-FirebirdDatabase -Database '/tmp/test.fdb' -Credential (Get-Credential)
        Creates a new database using a PSCredential object.
    .OUTPUTS
        FirebirdDatabase object with Environment and database connection properties.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [FirebirdDatabase]$Database,

        [PSCredential]$Credential,

        [string]$User = 'SYSDBA',

        [string]$Password = 'masterkey',

        [ValidateSet(4096, 8192, 16384, 32768)]
        [int]$PageSize = 8192,

        [string]$Charset = 'UTF8',

        [FirebirdEnvironment]$Environment = [FirebirdEnvironment]::default(),

        [switch]$Force
    )

    Write-VerboseMark -Message "Using Firebird environment at '$($Environment.Path)'"

    # If Credential is specified, extract User and Password from it
    if ($Credential) {
        $User = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
        Write-VerboseMark -Message "Using credentials from -Credential parameter for user '$User'."
    }

    if ($Database.Host) {
        # Remote database or local over xnet
        if ($Force) {
            throw "Cannot use -Force with remote databases or xnet protocol."
        }
    } else {
        # Local database connection
        if (Test-Path -Path $Database.Path -PathType Leaf) {
            if ($Force) {
                if ($PSCmdlet.ShouldProcess($Database.Path, 'Remove existing database file')) {
                    Write-VerboseMark -Message "Database file '$($Database.Path)' already exists and -Force specified. Removing database file..."
                    Remove-Item -Path $Database.Path -Force
                }
            } else {
                throw "Database file '$($Database.Path)' already exists. Use -Force to overwrite."
            }
        }
    }


    if ($PSCmdlet.ShouldProcess($Database.Path, 'Create new Firebird database')) {
        $createDbCmd = @"
CREATE DATABASE '$($Database.Path)' 
    USER '$User' 
    PASSWORD '$Password' 
    PAGE_SIZE $PageSize 
    DEFAULT CHARACTER SET $Charset;
"@

        $isql = $Environment.GetIsqlPath()
        
        Write-VerboseMark -Message "Creating database at '$($Database.Path)' with user '$($User)', page size $($PageSize), charset '$($Charset)'."
        Invoke-ExternalCommand {
            $createDbCmd | & $isql -quiet
        } -ErrorMessage 'Error running isql.'
        Write-VerboseMark -Message "Database created successfully at '$($Database.Path)'"
    }

    $odsVersion = Get-FirebirdODSVersion -Database $Database.Path

    # Return the database information as a FirebirdDatabase class instance.
    [FirebirdDatabase]::new(@{
            Path        = $Database.Path

            PageSize    = $PageSize
            ODSVersion  = $odsVersion
        })
}
