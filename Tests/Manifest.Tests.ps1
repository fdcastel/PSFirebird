Describe 'Manifest' -Tag 'Unit' {
    BeforeAll {
        $script:ManifestPath = "$PSScriptRoot/../PSFirebird.psd1"
        $script:Manifest = Import-PowerShellDataFile $ManifestPath
    }

    It 'FunctionsToExport matches the files in Public/.' {
        # The manifest lists exported functions by hand, while PSFirebird.psm1 exports by
        # filename. Nothing else keeps the two in agreement.
        $exported = $Manifest.FunctionsToExport | Sort-Object
        $onDisk = (Get-ChildItem "$PSScriptRoot/../Public/*.ps1").BaseName | Sort-Object

        Compare-Object $exported $onDisk | Should -BeNullOrEmpty
    }

    It 'Declares no wildcard exports.' {
        # Omitting these means '*', which prevents PowerShell from using the manifest for
        # command discovery and forces the module to load on every lookup.
        foreach ($key in 'CmdletsToExport', 'AliasesToExport', 'VariablesToExport') {
            $Manifest.Keys | Should -Contain $key
            $Manifest[$key] | Should -BeNullOrEmpty -Because "$key should be an empty array, not a wildcard"
        }
    }

    It 'Is a valid module manifest.' {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }
}
