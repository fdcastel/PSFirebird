Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

# Unit tests for the gstat parser, driven by a captured real `gstat -a -r` run
# (Tests/assets/gstat-output.txt, Firebird 5.0.3) so they need no Firebird installation.
#
# Tests/Statistics.Tests.ps1 covers the same parser end-to-end against a live server.

Describe 'ConvertFrom-Gstat' -Tag 'Unit' {
    BeforeAll {
        $script:GstatLines = Get-Content "$PSScriptRoot/assets/gstat-output.txt"
    }

    It 'Parses every table and index.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $result = $Lines | ConvertFrom-Gstat

            $result.tables.TableName | Should -Be @('CUSTOMERS', 'ORDERS')
            $result.indices.IndexName | Should -Be @('IDX_CUSTOMERS_NAME', 'PK_CUSTOMERS', 'PK_ORDERS')
        }
    }

    It 'Associates each index with its table.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $result = $Lines | ConvertFrom-Gstat

            ($result.indices | Where-Object IndexName -EQ 'PK_ORDERS').TableName | Should -Be 'ORDERS'
            ($result.indices | Where-Object IndexName -EQ 'PK_CUSTOMERS').TableName | Should -Be 'CUSTOMERS'
        }
    }

    It 'Parses table statistics with the expected values.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $customers = ($Lines | ConvertFrom-Gstat).tables | Where-Object TableName -EQ 'CUSTOMERS'

            $customers.TableId | Should -Be 128
            $customers.PrimaryPointerPage | Should -Be 225
            $customers.IndexRootPage | Should -Be 226
            $customers.TotalRecords | Should -Be 3
            $customers.AvgRecordLength | Should -Be 19.00
            $customers.AvgUnpackedLength | Should -Be 410.00
            $customers.CompressionRatio | Should -Be 21.58
            $customers.DataPages | Should -Be 1
            $customers.AvgFill | Should -Be 1
        }
    }

    It 'Parses index statistics with the expected values.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $index = ($Lines | ConvertFrom-Gstat).indices | Where-Object IndexName -EQ 'IDX_CUSTOMERS_NAME'

            $index.IndexId | Should -Be 1
            $index.RootPage | Should -Be 233
            $index.Depth | Should -Be 1
            $index.Nodes | Should -Be 3
            $index.AvgNodeLength | Should -Be 8.00
            $index.AvgKeyLength | Should -Be 6.00
            $index.CompressionRatio | Should -Be 0.67
            $index.ClusteringFactor | Should -Be 1
            $index.Ratio | Should -Be 0.33
        }
    }

    It 'Parses fill distributions for both tables and indices.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $result = $Lines | ConvertFrom-Gstat

            # Indices are indented more deeply than tables in real gstat output.
            $table = $result.tables | Where-Object TableName -EQ 'CUSTOMERS'
            $table.Fill_0_19 | Should -Be 1
            $table.Fill_20_39 | Should -Be 0

            $index = $result.indices | Where-Object IndexName -EQ 'PK_ORDERS'
            $index.Fill_0_19 | Should -Be 1
            $index.Fill_80_99 | Should -Be 0
        }
    }

    It 'Emits numeric fields as numbers, not strings.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $result = $Lines | ConvertFrom-Gstat
            $table = $result.tables[0]
            $index = $result.indices[0]

            $table.TableId | Should -BeOfType [int]
            $table.TotalRecords | Should -BeOfType [int]
            $table.DataPages | Should -BeOfType [int]
            $table.Fill_0_19 | Should -BeOfType [int]
            $table.AvgRecordLength | Should -BeOfType [double]
            $table.CompressionRatio | Should -BeOfType [double]

            $index.Nodes | Should -BeOfType [int]
            $index.Depth | Should -BeOfType [int]
            $index.Ratio | Should -BeOfType [double]
        }
    }

    It 'Sorts numerically rather than lexically.' {
        InModuleScope 'PSFirebird' {
            # A string sort puts '9' after '10'. This is why the fields are numbers.
            $lines = @(
                'SMALL (1)', '    Average record length: 1.00, total records: 9'
                'LARGE (2)', '    Average record length: 1.00, total records: 10'
            )
            $sorted = ($lines | ConvertFrom-Gstat).tables | Sort-Object TotalRecords

            $sorted.TableName | Should -Be @('SMALL', 'LARGE')
        }
    }

    It 'Is reentrant: a nested parse does not corrupt the outer one.' {
        InModuleScope 'PSFirebird' {
            # The previous implementation kept parser state in module-scoped $script:
            # variables, so the inner parse replaced OUTER_A with INNERTBL.
            $inner = @('INNERTBL (99)', '    Average record length: 1.00, total records: 5')
            $outer = @(
                'OUTER_A (1)', '    Average record length: 1.00, total records: 10'
                'OUTER_B (2)', '    Average record length: 2.00, total records: 20'
            )

            $result = $outer | ForEach-Object {
                if ($_ -match 'OUTER_B') { $null = $inner | ConvertFrom-Gstat }
                $_
            } | ConvertFrom-Gstat

            $result.tables.TableName | Should -Be @('OUTER_A', 'OUTER_B')
        }
    }

    It 'Retains no parser state between invocations.' {
        InModuleScope 'PSFirebird' -Parameters @{ Lines = $GstatLines } {
            $null = $Lines | ConvertFrom-Gstat
            $second = @('ONLYONE (7)', '    Average record length: 1.00, total records: 1') | ConvertFrom-Gstat

            $second.tables.Count | Should -Be 1 -Because 'results from the previous parse must not leak into this one'
            $second.indices.Count | Should -Be 0
        }
    }

    It 'Returns empty collections for input containing no statistics.' {
        InModuleScope 'PSFirebird' {
            $result = @('Database "x.fdb"', 'Analyzing database pages ...', '') | ConvertFrom-Gstat

            $result.tables.Count | Should -Be 0
            $result.indices.Count | Should -Be 0
        }
    }
}
