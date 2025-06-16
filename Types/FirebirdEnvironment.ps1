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

    # Common constructor for title and author
    FirebirdEnvironment([string]$Path, [version]$Version) {
        $this.Init(@{Path = $Path; Version = $Version })
    }

    # Shared initializer method
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }

    # Method to return a string representation of the class
    [string] ToString() {
        return "Firebird $($this.Version) at $($this.Path)"
    }
}
