. "$PSScriptRoot/../Private/Split-FirebirdConnectionString.ps1"

class FirebirdDatabase {
    # Class properties
    [string] $Protocol
    [string] $Host
    [string] $Port     # Empty/null means not specified
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
        $this.Init(@{ Protocol = $sp.Protocol; Host = $sp.Host; Port = $sp.Port; Path = $sp.Path })
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

    # Return true if the database is local (no remote host)
    [bool] IsLocal() {
        return -not $this.Host
    }

    # Return the port as an integer, or $null if not specified or not numeric
    [object] PortNumber() {
        if ($this.Port -and $this.Port -match '^\d+$') {
            return [int]$this.Port
        }
        return $null
    }

    # Return a connection string for Firebird tools
    [string] ConnectionString() {
        # xnet: always use URI format
        if ($this.Protocol -eq 'xnet') {
            return "xnet://$($this.Path)"
        }

        if ($this.Host) {
            # inet4/inet6: use URI format
            if ($this.Protocol -and $this.Protocol -ne 'inet') {
                $hostPart = if ($this.Protocol -eq 'inet6' -and $this.Host -match ':') {
                    "[$($this.Host)]"
                } else {
                    $this.Host
                }
                if ($this.Port) {
                    return "$($this.Protocol)://$($hostPart):$($this.Port)/$($this.Path)"
                }
                return "$($this.Protocol)://$($hostPart)/$($this.Path)"
            }

            # inet (default): use legacy format host[/port]:path
            if ($this.Port) {
                return "$($this.Host)/$($this.Port):$($this.Path)"
            }
            return "$($this.Host):$($this.Path)"
        }

        return $this.Path
    }
}
