function ConvertFrom-Gstat {
    <#
    .SYNOPSIS
        Parses `gstat -a -r` output into structured table and index statistics.
    .DESCRIPTION
        Accepts gstat output line by line from the pipeline and returns an object with
        'tables' and 'indices' properties. Numeric fields are emitted as numbers, so
        results can be sorted and compared arithmetically.

        The parsing itself lives in the [GstatParser] class, which keeps its state per
        instance -- nested or concurrent parses do not interfere.
    .PARAMETER InputLine
        A line of gstat output. Accepts pipeline input.
    .EXAMPLE
        & $environment.GetGstatPath() -a -r $database | ConvertFrom-Gstat
        Returns the parsed statistics for the database.
    .OUTPUTS
        PSCustomObject with 'tables' and 'indices' properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$InputLine
    )

    begin {
        $parser = [GstatParser]::new()
    }

    process {
        $parser.ProcessLine($InputLine)
    }

    end {
        $parser.Complete()
    }
}
