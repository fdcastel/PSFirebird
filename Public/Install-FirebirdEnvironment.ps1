function Install-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Downloads and extracts Firebird Embedded binaries for a given version and platform using GitHub releases.
    .PARAMETER Version
        The Firebird version to install (minimum 3.0.9), as a [semver] object.
    .PARAMETER OutputPath
        Optional. The directory to extract the binaries to. If not provided, a temporary folder is used.
    .PARAMETER RuntimeIdentifier
        Optional. The runtime identifier (RID) to use. If not provided, uses the current platform RID.
    .OUTPUTS
        [string] The path to the extracted Firebird Embedded root.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter(Mandatory)]
        [semver]$Version,

        [string]$OutputPath,

        [ValidateSet('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier
    )

    if (-not $IsWindows -and -not $IsLinux) {
        throw "Unsupported platform: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription). Only Windows and Linux are supported."
    }

    if ($IsLinux -and (-not (Get-Command apt -ErrorAction SilentlyContinue))) {
        throw 'apt command not found. Ensure you are running this on a Debian-based Linux distribution.'
    }

    $rid = if ($RuntimeIdentifier) { $RuntimeIdentifier } else { [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier }
    $supportedRIDs = @('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')
    if ($supportedRIDs -notcontains $rid) {
        throw "Unsupported RuntimeIdentifier: $rid. Supported: $($supportedRIDs -join ', ')"
    }
    Write-VerboseMark "RuntimeIdentifier is '$rid'."

    $minVersion = [semver]'3.0.9'
    if ($Version -lt $minVersion) {
        throw 'Firebird minimal supported version is 3.0.9.'
    }
    Write-VerboseMark "Requested Firebird version '$($Version)'"

    $tempRoot = [System.IO.Path]::GetTempPath()

    if (-not $OutputPath) {
        $OutputPath = Join-Path $tempRoot "firebird-$($Version)"
        Write-VerboseMark "No OutputPath specified. Using temporary folder: $OutputPath"
    }

    if (Test-Path $OutputPath) {
        if ($PSCmdlet.ShouldProcess($OutputPath, 'Clear existing output directory')) {
            Remove-Item $OutputPath -Recurse -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($OutputPath, 'Create output directory')) {
        New-Item -ItemType Directory $OutputPath -Force > $null
    }

    $downloadUrl = Get-FirebirdReleaseUrl -Version $Version -RuntimeIdentifier $rid
    Write-VerboseMark "Release URL is '$($downloadUrl)'"

    $archiveFile = ([uri]$downloadUrl).Segments[-1]
    $fullArchiveFile = Join-Path $tempRoot $archiveFile

    if ($PSCmdlet.ShouldProcess($archiveFile, 'Downloading Firebird archive')) {
        Write-VerboseMark "Downloading Firebird archive '$archiveFile'..."
        Invoke-WebRequest $downloadUrl -OutFile $fullArchiveFile -Verbose:$false
    }

    if ($PSCmdlet.ShouldProcess($archiveFile, 'Extracting archive')) {
        Write-VerboseMark "Extracting archive '$archiveFile'..."
        if ($IsWindows) {
            Expand-Archive -Path $fullArchiveFile -DestinationPath $OutputPath
        } elseif ($IsLinux) {
            tar --extract --file=$fullArchiveFile --gunzip --directory=$OutputPath --strip-components=1
            tar --extract --file="$OutputPath/buildroot.tar.gz" --gunzip --directory=$OutputPath --strip-components=3 ./opt
        }
    }

    if ($PSCmdlet.ShouldProcess($fullArchiveFile, 'Removing archive')) {
        Write-VerboseMark "Removing archive '$fullArchiveFile'..."
        Remove-Item @(
            # On Linux, also remove the buildroot archive
            "$OutputPath/buildroot.tar.gz",

            # Common
            $fullArchiveFile
        ) -Recurse -Force -ErrorAction Ignore
    }

    # Windows-only: Set the IpcName in firebird.conf
    if ($IsWindows) {
        $ipcName = "FIREBIRD-$($Version -replace '\.','_')"
        $firebirdConfPath = Join-Path $OutputPath 'firebird.conf'
        if ($PSCmdlet.ShouldProcess($firebirdConfPath, "Setting IpcName to '$ipcName' in firebird.conf")) {
            Write-VerboseMark "Setting IpcName to '$ipcName' in firebird.conf..."
            $content = Get-Content $firebirdConfPath
            $content = $content -replace '#IpcName = FIREBIRD', "IpcName = $ipcName"
            Set-Content -Path $firebirdConfPath -Value $content -Encoding Ascii
        }
    }

    # Linux-only: Download libtommath1 package and extract it to the `lib` directory.
    if ($IsLinux) {
        # The apt download command does not have a built-in option to set the download directory
        Push-Location $tempRoot
        try {
            Write-VerboseMark 'Downloading libtommath1 package...'
            apt download -y libtommath1
            dpkg-deb -x libtommath1_*.deb .

            $libPath = Join-Path $OutputPath 'lib'
            Write-VerboseMark "Extracting libtommath1 to '$libPath'..."
            Move-Item ./usr/lib/x86_64-linux-gnu/* $libPath

            # Fix libtommath for FB3 and FB4 -- https://github.com/FirebirdSQL/firebird/issues/5716#issuecomment-826239174
            if ($Version -lt [semver]5) {
                Write-VerboseMark 'Creating symlink for libtommath.so.0...'
                ln -sf "$libPath/libtommath.so.1" "$libPath/libtommath.so.0"
            }
        }
        finally {
            Pop-Location
        }
    }

    # Remove the sample database from databases.conf
    $databasesConfPath = Join-Path $OutputPath 'databases.conf'
    if ($PSCmdlet.ShouldProcess($databasesConfPath, 'Removing sample database')) {
        Write-VerboseMark "Removing sample database from '$databasesConfPath'..."
        $content = Get-Content $databasesConfPath
        $content | Where-Object { $_ -notmatch '^employee' } | Set-Content $databasesConfPath
    }

    # Clean up the output directory
    if ($PSCmdlet.ShouldProcess($OutputPath, 'Cleaning up output directory')) {
        Write-VerboseMark 'Cleaning up output directory...'
        Remove-Item @(
            # Windows-specific
            "$OutputPath/system32",
            "$OutputPath/*.bat",

            # Linux-specific
            "$OutputPath/buildroot.tar.gz",

            # Common files
            "$OutputPath/doc",
            "$OutputPath/examples",
            "$OutputPath/help",
            "$OutputPath/include",
            "$OutputPath/misc",
            
            $fullArchiveFile
        ) -Recurse -Force -ErrorAction Ignore
    }

    # Return the output path
    return $OutputPath
}
