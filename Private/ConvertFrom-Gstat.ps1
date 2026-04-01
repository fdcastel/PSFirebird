function ConvertTo-OrderedRecord {
    param(
        [System.Collections.IDictionary]$Source,
        [string[]]$PropertyNames
    )

    $record = [ordered]@{}
    foreach ($propertyName in $PropertyNames) {
        $record[$propertyName] = $Source[$propertyName]
    }

    return [PSCustomObject]$record
}

function Get-ParseResultPayload {
    return [PSCustomObject][ordered]@{
        tables = @($script:tableResults)
        indices = @($script:indexResults)
    }
}

function New-FillDistribution {
    return @{
        Fill_0_19 = 0
        Fill_20_39 = 0
        Fill_40_59 = 0
        Fill_60_79 = 0
        Fill_80_99 = 0
    }
}

function Set-FillDistributionFields {
    param(
        [System.Collections.IDictionary]$Target,
        [System.Collections.IDictionary]$Distribution
    )

    if ($null -eq $Target -or $null -eq $Distribution) {
        return
    }

    foreach ($propertyName in 'Fill_0_19', 'Fill_20_39', 'Fill_40_59', 'Fill_60_79', 'Fill_80_99') {
        $Target[$propertyName] = $Distribution[$propertyName]
    }
}

function Add-TableResult {
    param([System.Collections.IDictionary]$Table)

    if ($null -eq $Table) {
        return
    }

    [void]$script:tableResults.Add((ConvertTo-OrderedRecord -Source $Table -PropertyNames $script:tableColumnOrder))
}

function Add-IndexResult {
    param([System.Collections.IDictionary]$Index)

    if ($null -eq $Index) {
        return
    }

    [void]$script:indexResults.Add((ConvertTo-OrderedRecord -Source $Index -PropertyNames $script:indexColumnOrder))
}

function Start-FillDistributionCapture {
    param(
        [System.Collections.IDictionary]$Target,
        [string]$Context
    )

    if ($null -eq $Target) {
        return
    }

    $script:pendingFillTarget = $Target
    $script:pendingFillContext = $Context
    $script:pendingFillDistribution = New-FillDistribution
    $script:pendingFillLineCount = 0
}

function Complete-FillDistributionCapture {
    if ($null -eq $script:pendingFillTarget) {
        return
    }

    Set-FillDistributionFields -Target $script:pendingFillTarget -Distribution $script:pendingFillDistribution

    if ($script:pendingFillContext -eq 'Index' -and $null -ne $script:currentIndex) {
        Add-IndexResult -Index $script:currentIndex
        $script:currentIndex = $null
    }

    $script:pendingFillTarget = $null
    $script:pendingFillContext = $null
    $script:pendingFillDistribution = $null
    $script:pendingFillLineCount = 0
}

function Try-ConsumeFillDistributionLine {
    param([AllowEmptyString()][string]$Line)

    if ($null -eq $script:pendingFillTarget) {
        return $false
    }

    if ($Line -match '(\d+)\s*-\s*(\d+)%\s*=\s*(\d+)') {
        $range = "$($matches[1])-$($matches[2])"
        $count = [int]$matches[3]

        switch ($range) {
            '0-19'   { $script:pendingFillDistribution.Fill_0_19 = $count }
            '20-39'  { $script:pendingFillDistribution.Fill_20_39 = $count }
            '40-59'  { $script:pendingFillDistribution.Fill_40_59 = $count }
            '60-79'  { $script:pendingFillDistribution.Fill_60_79 = $count }
            '80-99'  { $script:pendingFillDistribution.Fill_80_99 = $count }
        }

        $script:pendingFillLineCount += 1
        if ($script:pendingFillLineCount -ge 5) {
            Complete-FillDistributionCapture
        }

        return $true
    }

    Complete-FillDistributionCapture
    return $false
}

function Start-IndexRecord {
    param(
        [string]$IndexName,
        [string]$IndexId
    )

    $script:currentIndex = @{
        TableName = $script:currentTable.TableName
        IndexName = $IndexName
        IndexId = $IndexId
    }
}

function Process-GstatLine {
    param([AllowEmptyString()][string]$Line)

    if (Try-ConsumeFillDistributionLine -Line $Line) {
        return
    }

    if ($null -ne $script:currentIndex) {
        switch -Regex ($Line) {
            '^\s*Root page: (\d+), depth: (\d+), leaf buckets: (\d+), nodes: (\d+)$' {
                $script:currentIndex.RootPage = $matches[1]
                $script:currentIndex.Depth = $matches[2]
                $script:currentIndex.LeafBuckets = $matches[3]
                $script:currentIndex.Nodes = $matches[4]
                return
            }
            '^\s*Average node length: ([\d\.]+), total dup: (\d+), max dup: (\d+)$' {
                $script:currentIndex.AvgNodeLength = $matches[1]
                $script:currentIndex.TotalDup = $matches[2]
                $script:currentIndex.MaxDup = $matches[3]
                return
            }
            '^\s*Average key length: ([\d\.]+), compression ratio: ([\d\.]+)$' {
                $script:currentIndex.AvgKeyLength = $matches[1]
                $script:currentIndex.CompressionRatio = $matches[2]
                return
            }
            '^\s*Average prefix length: ([\d\.]+), average data length: ([\d\.]+)$' {
                $script:currentIndex.AvgPrefixLength = $matches[1]
                $script:currentIndex.AvgDataLength = $matches[2]
                return
            }
            '^\s*Clustering factor: (\d+), ratio: ([\d\.]+)$' {
                $script:currentIndex.ClusteringFactor = $matches[1]
                $script:currentIndex.Ratio = $matches[2]
                return
            }
            '^\s*Fill distribution:$' {
                Start-FillDistributionCapture -Target $script:currentIndex -Context 'Index'
                return
            }
            '^\s*$' {
                Add-IndexResult -Index $script:currentIndex
                $script:currentIndex = $null
                return
            }
            '^\s*Index ([A-Z0-9_]+) \((\d+)\)$' {
                Add-IndexResult -Index $script:currentIndex
                Start-IndexRecord -IndexName $matches[1] -IndexId $matches[2]
                return
            }
            '^([A-Z0-9_]+) \((\d+)\)$' {
                Add-IndexResult -Index $script:currentIndex
                $script:currentIndex = $null
                Add-TableResult -Table $script:currentTable
                $script:currentTable = @{
                    TableName = $matches[1]
                    TableId = $matches[2]
                }
                return
            }
            default {
                return
            }
        }
    }

    switch -Regex ($Line) {
        '^([A-Z0-9_]+) \((\d+)\)$' {
            Add-TableResult -Table $script:currentTable
            $script:currentTable = @{
                TableName = $matches[1]
                TableId = $matches[2]
            }
            return
        }
        '^\s*Primary pointer page: (\d+), Index root page: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.PrimaryPointerPage = $matches[1]
                $script:currentTable.IndexRootPage = $matches[2]
            }
            return
        }
        '^\s*Total formats: (\d+), used formats: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.TotalFormats = $matches[1]
                $script:currentTable.UsedFormats = $matches[2]
            }
            return
        }
        '^\s*Average record length: ([\d\.]+), total records: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.AvgRecordLength = $matches[1]
                $script:currentTable.TotalRecords = $matches[2]
            }
            return
        }
        '^\s*Average version length: ([\d\.]+), total versions: (\d+), max versions: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.AvgVersionLength = $matches[1]
                $script:currentTable.TotalVersions = $matches[2]
                $script:currentTable.MaxVersions = $matches[3]
            }
            return
        }
        '^\s*Average fragment length: ([\d\.]+), total fragments: (\d+), max fragments: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.AvgFragmentLength = $matches[1]
                $script:currentTable.TotalFragments = $matches[2]
                $script:currentTable.MaxFragments = $matches[3]
            }
            return
        }
        '^\s*Average unpacked length: ([\d\.]+), compression ratio: ([\d\.]+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.AvgUnpackedLength = $matches[1]
                $script:currentTable.CompressionRatio = $matches[2]
            }
            return
        }
        '^\s*Pointer pages: (\d+), data page slots: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.PointerPages = $matches[1]
                $script:currentTable.DataPageSlots = $matches[2]
            }
            return
        }
        '^\s*Data pages: (\d+), average fill: (\d+)%$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.DataPages = $matches[1]
                $script:currentTable.AvgFill = $matches[2]
            }
            return
        }
        '^\s*Primary pages: (\d+), secondary pages: (\d+), swept pages: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.PrimaryPages = $matches[1]
                $script:currentTable.SecondaryPages = $matches[2]
                $script:currentTable.SweptPages = $matches[3]
            }
            return
        }
        '^\s*Empty pages: (\d+), full pages: (\d+)$' {
            if ($null -ne $script:currentTable) {
                $script:currentTable.EmptyPages = $matches[1]
                $script:currentTable.FullPages = $matches[2]
            }
            return
        }
        '^\s*Fill distribution:$' {
            Start-FillDistributionCapture -Target $script:currentTable -Context 'Table'
            return
        }
        '^\s*Index ([A-Z0-9_]+) \((\d+)\)$' {
            if ($null -ne $script:currentTable) {
                Start-IndexRecord -IndexName $matches[1] -IndexId $matches[2]
            }
            return
        }
    }
}

function Complete-Parse {
    if ($null -ne $script:pendingFillTarget) {
        Complete-FillDistributionCapture
    }

    if ($null -ne $script:currentIndex) {
        Add-IndexResult -Index $script:currentIndex
        $script:currentIndex = $null
    }

    if ($null -ne $script:currentTable) {
        Add-TableResult -Table $script:currentTable
        $script:currentTable = $null
    }
}

function ConvertFrom-Gstat {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$InputLine
    )

    begin {
        $script:tableColumnOrder = @(
            'TableName','TableId','PrimaryPointerPage','IndexRootPage','TotalFormats','UsedFormats',
            'AvgRecordLength','TotalRecords','AvgVersionLength','TotalVersions','MaxVersions',
            'AvgFragmentLength','TotalFragments','MaxFragments','AvgUnpackedLength','CompressionRatio',
            'PointerPages','DataPageSlots','DataPages','AvgFill','PrimaryPages','SecondaryPages','SweptPages',
            'EmptyPages','FullPages','Fill_0_19','Fill_20_39','Fill_40_59','Fill_60_79','Fill_80_99'
        )

        $script:indexColumnOrder = @(
            'TableName','IndexName','IndexId','RootPage','Depth','LeafBuckets','Nodes',
            'AvgNodeLength','TotalDup','MaxDup','AvgKeyLength','CompressionRatio','AvgPrefixLength',
            'AvgDataLength','ClusteringFactor','Ratio','Fill_0_19','Fill_20_39','Fill_40_59','Fill_60_79','Fill_80_99'
        )

        $script:tableResults = [System.Collections.Generic.List[object]]::new()
        $script:indexResults = [System.Collections.Generic.List[object]]::new()
        $script:currentTable = $null
        $script:currentIndex = $null
        $script:pendingFillTarget = $null
        $script:pendingFillContext = $null
        $script:pendingFillDistribution = $null
        $script:pendingFillLineCount = 0
    }

    process {
        if ($null -eq $InputLine) {
            return
        }

        Process-GstatLine -Line $InputLine
    }

    end {
        Complete-Parse

        Get-ParseResultPayload
    }
}
