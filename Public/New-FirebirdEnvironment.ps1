function New-FirebirdEnvironment {
    <#
    .SYNOPSIS
        Downloads and extracts Firebird binaries for a given version and platform.
    .DESCRIPTION
        Installs Firebird to a specified or temporary directory and returns environment details.
        Supports both official releases (by version) and snapshot builds (by branch).
    .PARAMETER Version
        Firebird version to install. Minimum supported version is 3.0.9.
    .PARAMETER Branch
        Snapshot branch to install from (e.g. 'master' for Firebird 6.x development builds,
        'v5.0-release' for Firebird 5.x next-patch builds, 'v4.0' for Firebird 4.x next-patch builds).
        Mutually exclusive with -Version.
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
    .EXAMPLE
        New-FirebirdEnvironment -Branch 'master'
        Installs the latest Firebird snapshot from the master branch to a temporary directory.
    .OUTPUTS
        FirebirdEnvironment object with Path and Version properties.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByVersion')]
    [OutputType([FirebirdEnvironment])]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'ByVersion')]
        [semver]$Version,

        [Parameter(Mandatory, ParameterSetName = 'ByBranch')]
        [ValidateSet('master', 'v5.0-release', 'v4.0')]
        [string]$Branch,

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
    Write-VerboseMark -Message "RuntimeIdentifier is '$rid'."

    # Resolve release info based on parameter set
    if ($PSCmdlet.ParameterSetName -eq 'ByBranch') {
        Write-VerboseMark -Message "Requested Firebird snapshot branch '$Branch'"
        $snapshotInfo = Find-FirebirdSnapshotRelease -Branch $Branch -RuntimeIdentifier $rid
        # Extract version from the snapshot filename (e.g. 'Firebird-6.0.0.1884-...' -> '6.0.0')
        if ($snapshotInfo.FileName -match 'Firebird-(\d+\.\d+\.\d+)') {
            $Version = [semver]$Matches[1]
        } else {
            throw "Cannot determine version from snapshot filename: $($snapshotInfo.FileName)"
        }
        Write-VerboseMark -Message "Resolved snapshot version: $Version"
    } else {
        Write-VerboseMark -Message "Requested Firebird version '$($Version)'"

        # Official Firebird releases only ship a Windows ARM64 binary from v6 onwards.
        # Auto-fall back to win-x64 (x64 emulation) when the host is win-arm64 and no
        # explicit -RuntimeIdentifier was provided, so callers on ARM64 Windows machines
        # don't get a confusing "asset not found" error for v3/v4/v5 installs.
        if ($rid -eq 'win-arm64' -and -not $RuntimeIdentifier -and $Version.Major -lt 6) {
            Write-Warning "No win-arm64 Firebird $Version binary exists; falling back to win-x64 (x64 emulation)."
            $rid = 'win-x64'
        }
    }

    $minVersion = [semver]'3.0.9'
    if ($Version -lt $minVersion) {
        throw 'Firebird minimal supported version is 3.0.9.'
    }

    $tempRoot = [System.IO.Path]::GetTempPath()

    if (-not $Path) {
        if ($PSCmdlet.ParameterSetName -eq 'ByBranch') {
            # Use the build number from the snapshot filename so that concurrent jobs or
            # consecutive runs of different snapshots of the same branch don't collide.
            $buildSuffix = if ($snapshotInfo.FileName -match '(\d+\.\d+\.\d+\.\d+)') { $Matches[1] } else { $Branch }
            $pathSuffix = "firebird-snapshot-$buildSuffix"
        } else {
            $pathSuffix = "firebird-$($Version)"
        }
        $Path = Join-Path $tempRoot $pathSuffix
        Write-VerboseMark -Message "No Path specified. Using temporary folder: $Path"
    }

    if (Test-Path $Path) {
        if (-not $Force) {
            Write-VerboseMark -Message "Path '$Path' already exists and -Force not specified."

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

    if ($PSCmdlet.ParameterSetName -eq 'ByBranch') {
        # Snapshot release info was already resolved above
        $releaseInfo = $snapshotInfo
    } else {
        $releaseInfo = Get-FirebirdReleaseUrl -Version $Version -RuntimeIdentifier $rid
    }
    $downloadUrl = $releaseInfo.Url
    Write-VerboseMark -Message "Release URL is '$($downloadUrl)'"

    $archiveFile = $releaseInfo.FileName
    $fullArchiveFile = Join-Path $tempRoot $archiveFile

    if ($PSCmdlet.ShouldProcess($archiveFile, 'Downloading Firebird archive')) {
        Write-VerboseMark -Message "Downloading Firebird archive '$archiveFile'..."
        Invoke-WebRequest $downloadUrl -OutFile $fullArchiveFile -Verbose:$false
    }

    if ($PSCmdlet.ShouldProcess($archiveFile, 'Extracting archive')) {
        Write-VerboseMark -Message "Extracting archive '$archiveFile'..."
        if ($IsWindows) {
            Write-VerboseMark -Message 'Extracting Windows archive...'
            Expand-Archive -Path $fullArchiveFile -DestinationPath $Path
        } elseif ($IsLinux) {
            Write-VerboseMark -Message 'Extracting Linux archive...'
            Invoke-ExternalCommand {
                & tar --extract --file=$fullArchiveFile --gunzip --directory=$Path --strip-components=1
            } -ErrorMessage "Failed to extract '$fullArchiveFile' archive. Cannot continue."

            if (-not ($rid.Contains('linux-arm64') -and ($Version.Major -lt 4))) {
                # FB3 arm64 archives ship binaries directly (no nested buildroot).
                # FB4+ arm64 and all x64 builds use a nested buildroot.tar.gz.
                Write-VerboseMark -Message 'Extracting buildroot archive...'
                Invoke-ExternalCommand {
                    & tar --extract --file="$Path/buildroot.tar.gz" --gunzip --directory=$Path --strip-components=3 ./opt
                } -ErrorMessage "Failed to extract '$fullArchiveFile' archive. Cannot continue."
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($fullArchiveFile, 'Removing archive')) {
        Write-VerboseMark -Message "Removing archive '$fullArchiveFile'..."
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
            Write-VerboseMark -Message "Setting IpcName to '$ipcName' in firebird.conf..."
            $content = Get-Content $firebirdConfPath
            $content = $content -replace '#IpcName = FIREBIRD', "IpcName = $ipcName"
            Set-Content -Path $firebirdConfPath -Value $content -Encoding Ascii
        }
    } else {
        Write-VerboseMark -Message 'Skipping IpcName configuration (not Windows).'
    }

    # Linux-only: Download additional packages and extract it to the `lib` directory.
    if ($IsLinux) {
        Write-VerboseMark -Message 'Downloading additional Linux packages...'
        $libPath = Join-Path $Path 'lib'

        Invoke-AptDownloadAndExtract -PackageName 'libtommath1' `
            -SourcePattern './usr/lib/*/*' `
            -TargetFolder $libPath

        # Firebird 3 binaries are compiled against the legacy ABI and need libncurses5/libtinfo5.
        # FB4+ link against ncurses6, which is pre-installed on all supported distros.
        # Ubuntu 24.04 removed libncurses5 from its repos, so we only download it for FB3.
        if ($Version.Major -eq 3) {
            Write-VerboseMark -Message 'Downloading libncurses5 and libtinfo5 for Firebird 3...'
            Invoke-AptDownloadAndExtract -PackageName 'libncurses5' `
                -SourcePattern './lib/*/*' `
                -TargetFolder $libPath

            Invoke-AptDownloadAndExtract -PackageName 'libtinfo5' `
                -SourcePattern './lib/*/*' `
                -TargetFolder $libPath
        }

        # Fix libtommath for FB3 and FB4 -- https://github.com/FirebirdSQL/firebird/issues/5716#issuecomment-826239174
        if ($Version -lt [semver]5) {
            Write-VerboseMark -Message 'Applying libtommath symlink fix for Firebird < 5...'
            if ($PSCmdlet.ShouldProcess("$libPath/libtommath.so.1", 'Creating symlink for libtommath.so.0...')) {
                Write-VerboseMark -Message 'Creating symlink for libtommath.so.0...'
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
        Write-VerboseMark -Message "Removing sample database from '$databasesConfPath'..."
        $content = Get-Content $databasesConfPath
        $content | Where-Object { $_ -notmatch '^employee' } | Set-Content $databasesConfPath
    }

    # Clean up the output directory
    if ($PSCmdlet.ShouldProcess($Path, 'Cleaning up output directory')) {
        Write-VerboseMark -Message 'Cleaning up output directory...'
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
