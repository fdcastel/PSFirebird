class FirebirdDatabase {
    # Class properties
    [FirebirdEnvironment] $Environment
    [string] $DatabasePath

    [int]$PageSize
    [version]$ODSVersion

    # Default constructor
    FirebirdDatabase() {
        $this.Init(@{})
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
        return "Firebird Database $($this.ODSVersion) at $($this.DatabasePath)"
    }
}
