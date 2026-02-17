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
                Write-VerboseMark -Message "Downloading '$PackageName' package..."
                Invoke-ExternalCommand {
                    & apt-get download -y $PackageName
                } -ErrorMessage "Failed to download '$PackageName' package. Cannot continue."

                Write-VerboseMark -Message "Extracting '$PackageName' to '$TargetFolder'..."
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
