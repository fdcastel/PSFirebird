# Parser for `gstat -a -r` output.
#
# This is an internal type: it is loaded by PSFirebird.psm1 but deliberately not registered
# as a type accelerator, since it is an implementation detail of ConvertFrom-Gstat.
#
# It exists as a class so that each parse owns its state. The previous implementation kept
# every field in module-scoped $script: variables shared by a dozen helper functions, which
# made nested parses corrupt each other and left parsed results resident in module memory
# after the pipeline finished.

class GstatParser {
    # Emitted property order, and the contract for what a record looks like.
    static [string[]] $TableColumnOrder = @(
        'TableName', 'TableId', 'PrimaryPointerPage', 'IndexRootPage', 'TotalFormats', 'UsedFormats',
        'AvgRecordLength', 'TotalRecords', 'AvgVersionLength', 'TotalVersions', 'MaxVersions',
        'AvgFragmentLength', 'TotalFragments', 'MaxFragments', 'AvgUnpackedLength', 'CompressionRatio',
        'PointerPages', 'DataPageSlots', 'DataPages', 'AvgFill', 'PrimaryPages', 'SecondaryPages', 'SweptPages',
        'EmptyPages', 'FullPages', 'Fill_0_19', 'Fill_20_39', 'Fill_40_59', 'Fill_60_79', 'Fill_80_99'
    )

    static [string[]] $IndexColumnOrder = @(
        'TableName', 'IndexName', 'IndexId', 'RootPage', 'Depth', 'LeafBuckets', 'Nodes',
        'AvgNodeLength', 'TotalDup', 'MaxDup', 'AvgKeyLength', 'CompressionRatio', 'AvgPrefixLength',
        'AvgDataLength', 'ClusteringFactor', 'Ratio', 'Fill_0_19', 'Fill_20_39', 'Fill_40_59', 'Fill_60_79', 'Fill_80_99'
    )

    # Properties parsed as fractional numbers. Everything else numeric is an integer.
    static [string[]] $DecimalProperties = @(
        'AvgRecordLength', 'AvgVersionLength', 'AvgFragmentLength', 'AvgUnpackedLength', 'CompressionRatio',
        'AvgNodeLength', 'AvgKeyLength', 'AvgPrefixLength', 'AvgDataLength', 'Ratio'
    )

    # Regex -> ordered property names for each capture group. Replaces eleven near-identical
    # switch branches that each repeated the same null guard and assignment shape.
    static [array] $TablePatterns = @(
        @{ Pattern = '^\s*Primary pointer page: (\d+), Index root page: (\d+)$'; Properties = @('PrimaryPointerPage', 'IndexRootPage') }
        @{ Pattern = '^\s*Total formats: (\d+), used formats: (\d+)$'; Properties = @('TotalFormats', 'UsedFormats') }
        @{ Pattern = '^\s*Average record length: ([\d\.]+), total records: (\d+)$'; Properties = @('AvgRecordLength', 'TotalRecords') }
        @{ Pattern = '^\s*Average version length: ([\d\.]+), total versions: (\d+), max versions: (\d+)$'; Properties = @('AvgVersionLength', 'TotalVersions', 'MaxVersions') }
        @{ Pattern = '^\s*Average fragment length: ([\d\.]+), total fragments: (\d+), max fragments: (\d+)$'; Properties = @('AvgFragmentLength', 'TotalFragments', 'MaxFragments') }
        @{ Pattern = '^\s*Average unpacked length: ([\d\.]+), compression ratio: ([\d\.]+)$'; Properties = @('AvgUnpackedLength', 'CompressionRatio') }
        @{ Pattern = '^\s*Pointer pages: (\d+), data page slots: (\d+)$'; Properties = @('PointerPages', 'DataPageSlots') }
        @{ Pattern = '^\s*Data pages: (\d+), average fill: (\d+)%$'; Properties = @('DataPages', 'AvgFill') }
        @{ Pattern = '^\s*Primary pages: (\d+), secondary pages: (\d+), swept pages: (\d+)$'; Properties = @('PrimaryPages', 'SecondaryPages', 'SweptPages') }
        @{ Pattern = '^\s*Empty pages: (\d+), full pages: (\d+)$'; Properties = @('EmptyPages', 'FullPages') }
    )

    static [array] $IndexPatterns = @(
        @{ Pattern = '^\s*Root page: (\d+), depth: (\d+), leaf buckets: (\d+), nodes: (\d+)$'; Properties = @('RootPage', 'Depth', 'LeafBuckets', 'Nodes') }
        @{ Pattern = '^\s*Average node length: ([\d\.]+), total dup: (\d+), max dup: (\d+)$'; Properties = @('AvgNodeLength', 'TotalDup', 'MaxDup') }
        @{ Pattern = '^\s*Average key length: ([\d\.]+), compression ratio: ([\d\.]+)$'; Properties = @('AvgKeyLength', 'CompressionRatio') }
        @{ Pattern = '^\s*Average prefix length: ([\d\.]+), average data length: ([\d\.]+)$'; Properties = @('AvgPrefixLength', 'AvgDataLength') }
        @{ Pattern = '^\s*Clustering factor: (\d+), ratio: ([\d\.]+)$'; Properties = @('ClusteringFactor', 'Ratio') }
    )

    # A table or index header: optionally schema-qualified and/or quoted, followed by its id.
    static [string] $TableHeaderPattern = '^(?:"[^"]+"\.)?"?([^"()\s]+)"? \((\d+)\)$'
    static [string] $IndexHeaderPattern = '^\s*Index (?:"[^"]+"\.)?"?([^"()\s]+)"? \((\d+)\)$'
    static [string] $FillDistributionHeader = '^\s*Fill distribution:$'
    static [string] $FillDistributionBucket = '(\d+)\s*-\s*(\d+)%\s*=\s*(\d+)'

    static [int] $FillBucketCount = 5

    hidden [System.Collections.Generic.List[object]] $TableResults
    hidden [System.Collections.Generic.List[object]] $IndexResults
    hidden [hashtable] $CurrentTable
    hidden [hashtable] $CurrentIndex
    hidden [hashtable] $PendingFillTarget
    hidden [string] $PendingFillContext
    hidden [int] $PendingFillLineCount

    GstatParser() {
        $this.TableResults = [System.Collections.Generic.List[object]]::new()
        $this.IndexResults = [System.Collections.Generic.List[object]]::new()
    }

    # Convert a captured string to the type the property expects. Parsing is culture
    # invariant: gstat always emits '.' as the decimal separator, regardless of locale.
    hidden static [object] ConvertValue([string]$propertyName, [string]$value) {
        if ([GstatParser]::DecimalProperties -contains $propertyName) {
            return [double]::Parse($value, [System.Globalization.CultureInfo]::InvariantCulture)
        }
        return [int]::Parse($value, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    hidden static [PSCustomObject] ToRecord([hashtable]$source, [string[]]$propertyNames) {
        $record = [ordered]@{}
        foreach ($propertyName in $propertyNames) {
            $record[$propertyName] = $source[$propertyName]
        }
        return [PSCustomObject]$record
    }

    # Try each pattern in $patterns against $line, writing captures into $target.
    hidden static [bool] TryApplyPatterns([array]$patterns, [string]$line, [hashtable]$target) {
        foreach ($entry in $patterns) {
            if ($line -match $entry.Pattern) {
                if ($null -ne $target) {
                    for ($i = 0; $i -lt $entry.Properties.Count; $i++) {
                        $name = $entry.Properties[$i]
                        $target[$name] = [GstatParser]::ConvertValue($name, $Matches[$i + 1])
                    }
                }
                return $true
            }
        }
        return $false
    }

    hidden [void] AddTableResult() {
        if ($null -ne $this.CurrentTable) {
            $this.TableResults.Add([GstatParser]::ToRecord($this.CurrentTable, [GstatParser]::TableColumnOrder))
        }
    }

    hidden [void] AddIndexResult() {
        if ($null -ne $this.CurrentIndex) {
            $this.IndexResults.Add([GstatParser]::ToRecord($this.CurrentIndex, [GstatParser]::IndexColumnOrder))
        }
    }

    hidden [void] StartFillCapture([hashtable]$target, [string]$context) {
        if ($null -eq $target) { return }

        $this.PendingFillTarget = $target
        $this.PendingFillContext = $context
        $this.PendingFillLineCount = 0
        foreach ($bucket in 'Fill_0_19', 'Fill_20_39', 'Fill_40_59', 'Fill_60_79', 'Fill_80_99') {
            $target[$bucket] = 0
        }
    }

    hidden [void] CompleteFillCapture() {
        if ($null -eq $this.PendingFillTarget) { return }

        # An index's fill distribution is the last thing gstat prints for it, so the record
        # is complete and can be emitted here.
        if ($this.PendingFillContext -eq 'Index' -and $null -ne $this.CurrentIndex) {
            $this.AddIndexResult()
            $this.CurrentIndex = $null
        }

        $this.PendingFillTarget = $null
        $this.PendingFillContext = $null
        $this.PendingFillLineCount = 0
    }

    # Returns true when the line was consumed as a fill-distribution bucket.
    hidden [bool] TryConsumeFillLine([string]$line) {
        if ($null -eq $this.PendingFillTarget) { return $false }

        if ($line -match [GstatParser]::FillDistributionBucket) {
            $bucketName = "Fill_$($Matches[1])_$($Matches[2])"
            $this.PendingFillTarget[$bucketName] = [int]$Matches[3]

            $this.PendingFillLineCount++
            if ($this.PendingFillLineCount -ge [GstatParser]::FillBucketCount) {
                $this.CompleteFillCapture()
            }
            return $true
        }

        $this.CompleteFillCapture()
        return $false
    }

    hidden [void] StartIndexRecord([string]$indexName, [string]$indexId) {
        $this.CurrentIndex = @{
            TableName = $this.CurrentTable.TableName
            IndexName = $indexName
            IndexId   = [int]$indexId
        }
    }

    hidden [void] StartTableRecord([string]$tableName, [string]$tableId) {
        $this.CurrentTable = @{
            TableName = $tableName
            TableId   = [int]$tableId
        }
    }

    [void] ProcessLine([string]$line) {
        if ($this.TryConsumeFillLine($line)) { return }

        if ($null -ne $this.CurrentIndex) {
            if ([GstatParser]::TryApplyPatterns([GstatParser]::IndexPatterns, $line, $this.CurrentIndex)) { return }

            if ($line -match [GstatParser]::FillDistributionHeader) {
                $this.StartFillCapture($this.CurrentIndex, 'Index')
                return
            }

            # A blank line ends the current index.
            if ($line -match '^\s*$') {
                $this.AddIndexResult()
                $this.CurrentIndex = $null
                return
            }

            if ($line -match [GstatParser]::IndexHeaderPattern) {
                $this.AddIndexResult()
                $this.StartIndexRecord($Matches[1], $Matches[2])
                return
            }

            # A table header while an index is open ends both.
            if ($line -match [GstatParser]::TableHeaderPattern) {
                $this.AddIndexResult()
                $this.CurrentIndex = $null
                $this.AddTableResult()
                $this.StartTableRecord($Matches[1], $Matches[2])
            }

            return
        }

        if ($line -match [GstatParser]::TableHeaderPattern) {
            $this.AddTableResult()
            $this.StartTableRecord($Matches[1], $Matches[2])
            return
        }

        if ([GstatParser]::TryApplyPatterns([GstatParser]::TablePatterns, $line, $this.CurrentTable)) { return }

        if ($line -match [GstatParser]::FillDistributionHeader) {
            $this.StartFillCapture($this.CurrentTable, 'Table')
            return
        }

        if ($line -match [GstatParser]::IndexHeaderPattern) {
            if ($null -ne $this.CurrentTable) {
                $this.StartIndexRecord($Matches[1], $Matches[2])
            }
        }
    }

    # Flush any records still open and return the parsed result.
    [PSCustomObject] Complete() {
        $this.CompleteFillCapture()

        if ($null -ne $this.CurrentIndex) {
            $this.AddIndexResult()
            $this.CurrentIndex = $null
        }

        if ($null -ne $this.CurrentTable) {
            $this.AddTableResult()
            $this.CurrentTable = $null
        }

        return [PSCustomObject][ordered]@{
            tables  = @($this.TableResults)
            indices = @($this.IndexResults)
        }
    }
}
