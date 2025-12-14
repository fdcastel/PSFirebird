class FirebirdInstance {
    # Class properties
    [FirebirdEnvironment] $Environment
    [System.Diagnostics.Process] $Process

    [int] $Port

    # Default constructor
    FirebirdInstance() {
        $this.Init(@{})
    }

    # Convenience constructor from hashtable
    FirebirdInstance([hashtable]$Properties) { 
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
        return "Firebird $($this.Environment.Version) instance listening at $($this.Port)"
    }
}
