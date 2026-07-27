Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

# Regression tests for -WhatIf / -Confirm handling.
#
# Background: these cmdlets used `if ($Force -or $PSCmdlet.ShouldProcess(...))`, where -or
# short-circuits and ShouldProcess is never called -- so -Force also disabled -WhatIf.
#
# For these two cmdlets the damage was contained, because the work is done by Remove-Item,
# which is itself ShouldProcess-aware and honours the inherited $WhatIfPreference. The
# observable defect was a misleading -WhatIf message ("Remove File" from Remove-Item rather
# than "Remove Firebird database"). Remove-FirebirdService was genuinely broken by the same
# pattern -- see Tests/FirebirdService.Tests.ps1 -- because it deletes via sc.exe/systemctl,
# native commands that ignore -WhatIf entirely.
#
# These need no Firebird installation: Remove-FirebirdDatabase only inspects the filesystem,
# and Remove-FirebirdEnvironment only probes for a gstat binary.

Describe 'ShouldProcess' -Tag 'Unit' {
    BeforeAll {
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)
    }

    AfterAll {
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Remove-FirebirdDatabase' {
        BeforeEach {
            $script:DbPath = Join-Path $RootFolder "$(New-Guid).fdb"
            New-Item -ItemType File -Path $DbPath | Out-Null
        }

        It '-WhatIf does not remove the database.' {
            Remove-FirebirdDatabase -Database $DbPath -WhatIf
            $DbPath | Should -Exist
        }

        It '-Force -WhatIf does not remove the database.' {
            # -Force must suppress the prompt without disabling -WhatIf.
            Remove-FirebirdDatabase -Database $DbPath -Force -WhatIf
            $DbPath | Should -Exist
        }

        It '-Force removes the database without prompting.' {
            Remove-FirebirdDatabase -Database $DbPath -Force
            $DbPath | Should -Not -Exist
        }

        It '-Confirm:$false removes the database.' {
            Remove-FirebirdDatabase -Database $DbPath -Confirm:$false
            $DbPath | Should -Not -Exist
        }
    }

    Context 'Remove-FirebirdEnvironment' {
        BeforeEach {
            # A directory is recognised as an environment by the presence of gstat.
            $script:EnvPath = Join-Path $RootFolder (New-Guid)
            if ($IsWindows) {
                New-Item -ItemType Directory -Path $EnvPath | Out-Null
                New-Item -ItemType File -Path (Join-Path $EnvPath 'gstat.exe') | Out-Null
            } else {
                New-Item -ItemType Directory -Path (Join-Path $EnvPath 'bin') -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $EnvPath 'bin/gstat') | Out-Null
            }
        }

        It '-WhatIf does not remove the environment.' {
            Remove-FirebirdEnvironment -Path $EnvPath -WhatIf
            $EnvPath | Should -Exist
        }

        It '-Force -WhatIf does not remove the environment.' {
            Remove-FirebirdEnvironment -Path $EnvPath -Force -WhatIf
            $EnvPath | Should -Exist
        }

        It '-Force removes the environment without prompting.' {
            Remove-FirebirdEnvironment -Path $EnvPath -Force
            $EnvPath | Should -Not -Exist
        }
    }
}
