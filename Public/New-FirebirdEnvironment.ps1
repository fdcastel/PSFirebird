function New-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Downloads and extracts Firebird binaries for a given version and platform.
    .DESCRIPTION
        Installs Firebird to a specified or temporary directory and returns environment details.
    .PARAMETER Version
        Firebird version to install. Minimum supported version is 3.0.9.
    .PARAMETER Path
        Directory to extract the binaries to. Uses a temporary folder if not provided.
    .PARAMETER RuntimeIdentifier
        Runtime identifier for the platform. Uses current platform if not specified.
    .PARAMETER Force
        Overwrites the output directory if it already exists.
    .EXAMPLE
        New-FirebirdEnvironment -Version 5.0.2 -Path '/tmp/firebird-5.0.2' -Force
        Installs Firebird 5.0.2 to the specified path, overwriting if it exists.
    .EXAMPLE
        New-FirebirdEnvironment -Version 5.0.2
        Installs Firebird 5.0.2 to a temporary directory.
    .OUTPUTS
        FirebirdEnvironment object with Path and Version properties.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter(Mandatory)]
        [semver]$Version,

        [string]$Path,

        [ValidateSet('win-x86', 'win-x64', 'win-arm64', 'linux-x64', 'linux-arm64')]
        [string]$RuntimeIdentifier,

        [switch]$Force
    )

    if (-not $IsWindows -and -not $IsLinux) {
        throw "Unsupported platform: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription). Only Windows and Linux are supported."
    }

    if ($IsLinux -and (-not (Get-Command 'apt-get' -ErrorAction SilentlyContinue))) {
        throw 'apt-get command not found. Ensure you are running this on a Debian-based Linux distribution.'
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

    if (-not $Path) {
        $Path = Join-Path $tempRoot "firebird-$($Version)"
        Write-VerboseMark "No Path specified. Using temporary folder: $Path"
    }

    if (Test-Path $Path) {
        if (-not $Force) {
            Write-VerboseMark "Path '$Path' already exists and -Force not specified."

            # Check if the existing path is a valid Firebird environment
            $existingEnvironment = Get-FirebirdEnvironment -Path $Path

            # Check if the existing environment version matches the requested version (discard Revision/Build number)
            $v = $existingEnvironment.Version
            $existingVersion = [semver]::new($v.Major, $v.Minor, $v.Build)
            if ($existingVersion -ne $Version) {
                throw "Path '$Path' already exists with version '$($existingVersion)'. Cannot install version '$Version'. Use -Force to overwrite."
            }

            # If the existing environment matches the requested version, return it
            return $existingEnvironment
        }
        if ($PSCmdlet.ShouldProcess($Path, 'Clear existing output directory')) {
            Remove-Item $Path -Recurse -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Create output directory')) {
        New-Item -ItemType Directory $Path -Force > $null
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
            Expand-Archive -Path $fullArchiveFile -DestinationPath $Path
        } elseif ($IsLinux) {
            if ($rid.Contains('linux-arm64') -and ($Version.Major -lt 5)) {
                # For Firebird 4.0 and earlier, the ARM64 archive has a different structure (no 'buildroot.tar.gz').
                Invoke-ExternalCommand {
                    & tar --extract --file=$fullArchiveFile --gunzip --directory=$Path --strip-components=1
                } -ErrorMessage "Failed to extract '$fullArchiveFile' archive. Cannot continue."
            } else {
                Invoke-ExternalCommand {
                    & tar --extract --file=$fullArchiveFile --gunzip --directory=$Path --strip-components=1
                } -ErrorMessage "Failed to extract '$fullArchiveFile' archive. Cannot continue."

                Invoke-ExternalCommand {
                    & tar --extract --file="$Path/buildroot.tar.gz" --gunzip --directory=$Path --strip-components=3 ./opt
                } -ErrorMessage "Failed to extract '$fullArchiveFile' archive. Cannot continue."
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($fullArchiveFile, 'Removing archive')) {
        Write-VerboseMark "Removing archive '$fullArchiveFile'..."
        Remove-Item -Path @(
            # On Linux, also remove the buildroot archive
            "$Path/buildroot.tar.gz",

            # Common
            $fullArchiveFile
        ) -Recurse -Force -ErrorAction Ignore
    }

    # Windows-only: Set the IpcName in firebird.conf
    if ($IsWindows) {
        $ipcName = "FIREBIRD-$($Version -replace '\.','_')"
        $firebirdConfPath = Join-Path $Path 'firebird.conf'
        if ($PSCmdlet.ShouldProcess($firebirdConfPath, "Setting IpcName to '$ipcName' in firebird.conf")) {
            Write-VerboseMark "Setting IpcName to '$ipcName' in firebird.conf..."
            $content = Get-Content $firebirdConfPath
            $content = $content -replace '#IpcName = FIREBIRD', "IpcName = $ipcName"
            Set-Content -Path $firebirdConfPath -Value $content -Encoding Ascii
        }
    }

    # Linux-only: Download additional packages and extract it to the `lib` directory.
    if ($IsLinux) {
        $libPath = Join-Path $Path 'lib'

        Invoke-AptDownloadAndExtract -PackageName 'libtommath1' `
            -SourcePattern './usr/lib/*/*' `
            -TargetFolder $libPath

        # For FB3, we also need to download libncurses5
        if ($Version -ge [semver]3) {
            Invoke-AptDownloadAndExtract -PackageName 'libncurses5' `
                -SourcePattern './lib/*/*' `
                -TargetFolder $libPath

            Invoke-AptDownloadAndExtract -PackageName 'libtinfo5' `
                -SourcePattern './lib/*/*' `
                -TargetFolder $libPath
        }

        # Fix libtommath for FB3 and FB4 -- https://github.com/FirebirdSQL/firebird/issues/5716#issuecomment-826239174
        if ($Version -lt [semver]5) {
            if ($PSCmdlet.ShouldProcess("$libPath/libtommath.so.1", 'Creating symlink for libtommath.so.0...')) {
                Write-VerboseMark 'Creating symlink for libtommath.so.0...'
                ln -sf "$libPath/libtommath.so.1" "$libPath/libtommath.so.0"
            }
        }
    }

    # Remove the sample database from databases.conf
    $databasesConfPath = Join-Path $Path 'databases.conf'
    if (-not (Test-Path $databasesConfPath)) {
        $folderItems = Get-ChildItem -Path $Path
        throw "databases.conf not found at '$Path'. Folder content is: $folderItems"
    }
    
    if ($PSCmdlet.ShouldProcess($databasesConfPath, 'Removing sample database')) {
        Write-VerboseMark "Removing sample database from '$databasesConfPath'..."
        $content = Get-Content $databasesConfPath
        $content | Where-Object { $_ -notmatch '^employee' } | Set-Content $databasesConfPath
    }

    # Clean up the output directory
    if ($PSCmdlet.ShouldProcess($Path, 'Cleaning up output directory')) {
        Write-VerboseMark 'Cleaning up output directory...'
        Remove-Item -Path @(
            # Windows-specific
            "$Path/system32",
            "$Path/*.bat",

            # Linux-specific
            "$Path/buildroot.tar.gz",

            # Common files
            "$Path/doc",
            "$Path/examples",
            "$Path/help",
            "$Path/include",
            "$Path/misc",

            $fullArchiveFile
        ) -Recurse -Force -ErrorAction Ignore
    }

    # Return the environment information as a FirebirdEnvironment class instance.
    Get-FirebirdEnvironment -Path $Path
}

function Invoke-AptDownloadAndExtract {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [string]$PackageName,
        [string]$SourcePattern,
        [string]$TargetFolder
    )
    if ($PSCmdlet.ShouldProcess($TargetFolder, "Downloading and extracting package $PackageName")) {
        # Create temporary folder -- https://tinyurl.com/rb82j8k4
        $tempFolder = New-Item -ItemType Directory -Path $([IO.Path]::GetTempPath()) -Name "tmp$($(Get-Random).ToString('X'))"
        try {
            # The apt-get download command does not have a built-in option to set the download directory
            Push-Location $tempFolder
            try {
                Write-VerboseMark "Downloading '$PackageName' package..."
                Invoke-ExternalCommand {
                    & apt-get download -y $PackageName
                } -ErrorMessage "Failed to download '$PackageName' package. Cannot continue."

                Write-VerboseMark "Extracting '$PackageName' to '$TargetFolder'..."
                $fullPackagePath = Resolve-Path "$($PackageName)_*.deb"
                Invoke-ExternalCommand {
                    & dpkg-deb -X $fullPackagePath .
                } -ErrorMessage "Failed to extract '$PackageName' package. Cannot continue."

                Move-Item $SourcePattern $TargetFolder -Force
            } finally {
                Pop-Location
            }
        } finally {
            Remove-Item -Path $tempFolder -Recurse -Force
        }
    }
}
