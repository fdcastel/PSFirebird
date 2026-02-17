class FirebirdEnvironment {
    # Class properties
    [string] $Path
    [version]$Version

    # Default constructor
    FirebirdEnvironment() {
        $this.Init(@{})
    }

    # String constructor for implicit type conversion
    FirebirdEnvironment([string]$Path) {
        $this.Init(@{ Path = $Path })
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

    # Return Firebird executable location
    [System.Management.Automation.PathInfo] GetServerPath() {
        return $this.GetFirebirdToolPath('firebird')
    }

    # Return isql location
    [System.Management.Automation.PathInfo] GetIsqlPath() {
        return $this.GetFirebirdToolPath('isql')
    }

    # Return gstat location
    [System.Management.Automation.PathInfo] GetGstatPath() {
        return $this.GetFirebirdToolPath('gstat')
    }

    # Return gbak location
    [System.Management.Automation.PathInfo] GetGbakPath() {
        return $this.GetFirebirdToolPath('gbak')
    }

    # Return nbackup location
    [System.Management.Automation.PathInfo] GetNbackupPath() {
        return $this.GetFirebirdToolPath('nbackup')
    }

    # Private helper to get tool path
    hidden [System.Management.Automation.PathInfo] GetFirebirdToolPath([string]$tool) {
        $toolPath = if ($global:IsWindows) {
            Join-Path $this.Path ("$tool.exe")
        } else {
            Join-Path $this.Path ("bin/$tool")
        }
        return Resolve-Path $toolPath
    }

    # Return the current context environment (set by Use-FirebirdEnvironment). Used as a default value for parameters.
    static [FirebirdEnvironment] default() {
        # Do not use Verbose messages here.
        $scope = 1
        while ($true) {
            try {
                $contextEnvironment = Get-Variable -Name 'FirebirdEnvironment' -Scope $scope -ValueOnly -ErrorAction SilentlyContinue
                if ($contextEnvironment) {
                    # Found a FirebirdEnvironment in the current scope
                    Write-Verbose "Found FirebirdEnvironment at scope $($scope): $($contextEnvironment)"
                    return $contextEnvironment
                }
                $scope++
            } catch [System.Management.Automation.PSArgumentOutOfRangeException] {
                # Get-Variable raises this exception when the scope exceeds the maximum. 
                #   This occurs during the argument processing phase of the cmdlet. -ErrorVariable does not catch it.
                Write-Verbose "No FirebirdEnvironment found up to scope $($scope). Error: $($_.Exception.Message)"
                break;
            }
        }

        # Try to get environment from FIREBIRD_ENVIRONMENT environment variable
        $envPath = [System.Environment]::GetEnvironmentVariable('FIREBIRD_ENVIRONMENT')
        if ($envPath) {
            Write-Verbose "Using Firebird environment from FIREBIRD_ENVIRONMENT: $($envPath)"
            return [FirebirdEnvironment]::new($envPath)
        }

        # If no environment found, throw an error
        throw 'No Firebird environment available. Use -Environment parameter, Use-FirebirdEnvironment, or set FIREBIRD_ENVIRONMENT environment variable.'
    }
}
