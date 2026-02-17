. "$PSScriptRoot/../Private/Split-FirebirdConnectionString.ps1"

class FirebirdDatabase {
    # Class properties
    [string] $Host
    [int] $Port     # 0 means not specified (PS classes don't support Nullable[int])
    [string] $Path

    [int] $PageSize
    [version] $ODSVersion

    # Default constructor
    FirebirdDatabase() {
        $this.Init(@{})
    }

    # String constructor for implicit type conversion
    FirebirdDatabase([string]$connectionString) {
        $sp = Split-FirebirdConnectionString -ConnectionString $connectionString
        $this.Init(@{ Host = $sp.Host; Port = [int]$sp.Port; Path = $sp.Path })
    }

    # Convenience constructor from hashtable
    FirebirdDatabase([hashtable]$Properties) {
        $this.Init($Properties)
    }

    # Shared initializer method
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }

    # Return a string representation of the class
    [string] ToString() {
        $connectionString = $this.ConnectionString()
        if ($this.Host) {
            return "Remote Firebird Database at $connectionString"
        } else {
            return "Local Firebird Database at $connectionString (ODS $($this.ODSVersion))"
        }
    }

    # Return a string representation of the class
    [string] ConnectionString() {
        if ($this.Host) {
            if ($this.Port) {
                return "$($this.Host)/$($this.Port):$($this.Path)"
            }
            return "$($this.Host):$($this.Path)"
        }
        return $this.Path
    }
}
