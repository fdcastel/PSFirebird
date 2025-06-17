class FirebirdEnvironment {
    # Class properties
    [string] $Path
    [version]$Version

    # Default constructor
    FirebirdEnvironment() {
        $this.Init(@{})
    }

    # Convenience constructor from hashtable
    FirebirdEnvironment([hashtable]$Properties) { 
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
        return "Firebird $($this.Version) at $($this.Path)"
    }

    # Return isql location
    [System.Management.Automation.PathInfo] GetIsqlPath() { 
        $isqlPath = if ($global:IsWindows) { 
            Join-Path $this.Path 'isql.exe'
        } else {
            Join-Path $this.Path 'bin/isql'
        }

        return Resolve-Path $isqlPath
    }

    # Return gstat location
    [System.Management.Automation.PathInfo] GetGstatPath() { 
        $gstatPath = if ($global:IsWindows) { 
            Join-Path $this.Path 'gstat.exe'
        } else {
            Join-Path $this.Path 'bin/gstat'
        }

        return Resolve-Path $gstatPath
    }

    # Return gbak location
    [System.Management.Automation.PathInfo] GetGbakPath() { 
        $gbakPath = if ($global:IsWindows) { 
            Join-Path $this.Path 'gbak.exe'
        } else {
            Join-Path $this.Path 'bin/gbak'
        }

        return Resolve-Path $gbakPath
    }
}
