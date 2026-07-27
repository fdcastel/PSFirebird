Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

# Regression tests for pipeline handling.
#
# Eight cmdlets declared ValueFromPipeline but had no process{} block. Without one the
# whole function body is the end block, so a pipeline-bound parameter holds only the LAST
# item and every earlier item is silently discarded.
#
# The structural test below is the load-bearing one: it fails for any cmdlet that declares
# ValueFromPipeline without a process block, including cmdlets added later.

Describe 'Pipeline' -Tag 'Unit' {

    It 'Every cmdlet declaring ValueFromPipeline has a process block.' {
        $tokens = $null
        $errors = $null
        $offenders = @()

        foreach ($file in Get-ChildItem "$PSScriptRoot/../Public/*.ps1") {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty -Because "$($file.Name) must parse cleanly"

            $function = $ast.FindAll(
                { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
                Select-Object -First 1
            if (-not $function) { continue }

            $pipelineParams = $function.Body.ParamBlock.Parameters |
                Where-Object { $_.Attributes.NamedArguments.ArgumentName -contains 'ValueFromPipeline' }

            if ($pipelineParams -and -not $function.Body.ProcessBlock) {
                $offenders += $file.BaseName
            }
        }

        $offenders | Should -BeNullOrEmpty -Because 'a pipeline parameter without a process block silently keeps only the last item'
    }

    Context 'Multiple items are processed' {
        BeforeAll {
            $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)
        }

        AfterAll {
            Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Remove-FirebirdDatabase removes every piped database.' {
            $paths = 1..3 | ForEach-Object {
                $p = Join-Path $RootFolder "multi-$_.fdb"
                New-Item -ItemType File -Path $p | Out-Null
                $p
            }

            $paths | Remove-FirebirdDatabase -Force

            foreach ($p in $paths) { $p | Should -Not -Exist }
        }

        It 'Write-FirebirdConfiguration applies every piped hashtable.' {
            $conf = Join-Path $RootFolder 'firebird.conf'
            Set-Content -Path $conf -Value @('#RemoteServicePort = 3050', '#DefaultDbCachePages = 2048')

            @{ RemoteServicePort = 3055 }, @{ DefaultDbCachePages = 4096 } |
                Write-FirebirdConfiguration -Path $conf

            $result = Read-FirebirdConfiguration -Path $conf
            $result['RemoteServicePort'] | Should -Be '3055'
            $result['DefaultDbCachePages'] | Should -Be '4096' -Because 'the second piped hashtable must not be discarded'
        }
    }
}
