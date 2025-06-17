# PSFirebird

<img src="docs/PSFirebird-logo.png" alt="PSFirebird Logo" width="180" align="right" />

A PowerShell module for managing Firebird database environments, databases, and utilities on Windows and Linux.

## Features
- Download and manage multiple Firebird environments and versions
- Create, inspect, and read Firebird databases
- Run SQL scripts and queries using Firebird's isql utility
- Switch between environments for multi-version support

## Requirements
- PowerShell 7.4 or later
- Windows or Linux (Debian-based for Linux)

## Installation
Clone or download this repository, then import the module:

```powershell
Import-Module ./PSFirebird.psm1
```

## Usage

## Cmdlets Overview
- `New-FirebirdEnvironment` – Download and set up a Firebird environment
- `Use-FirebirdEnvironment` – Set the current environment for the session
- `Get-FirebirdEnvironment` – Inspect a Firebird environment
- `New-FirebirdDatabase` – Create a new Firebird database
- `Get-FirebirdDatabase` – Get database and environment info
- `Read-FirebirdDatabase` – Read detailed database properties
- `Invoke-FirebirdIsql` – Run SQL scripts or queries
- `Read-FirebirdConfiguration` – Read all active (non-commented) config entries from a Firebird config file
- `Write-FirebirdConfiguration` – Update, add, or comment out config entries in a Firebird config file

### Set Up a Firebird Environment
```powershell
# Download and extract Firebird 5.0.2 to a specific folder
New-FirebirdEnvironment -Version 5.0.2 -Path 'C:/Firebird/env1' -Force

# Use the environment for subsequent commands
Use-FirebirdEnvironment -Environment (Get-FirebirdEnvironment -Path 'C:/Firebird/env1')
```

### Create a New Database
```powershell
New-FirebirdDatabase -DatabasePath 'C:/Firebird/data/test.fdb' -Force
```

### Get Database Information
```powershell
Get-FirebirdDatabase -DatabasePath 'C:/Firebird/data/test.fdb'
Read-FirebirdDatabase -DatabasePath 'C:/Firebird/data/test.fdb'
```

### Run SQL Against a Database
```powershell
Invoke-FirebirdIsql -DatabasePath 'C:/Firebird/data/test.fdb' -Sql 'SELECT * FROM RDB$DATABASE;'
```

## Configuration File Management

### Read Active Configuration Entries
```powershell
$config = Read-FirebirdConfiguration -Path 'C:/Firebird/firebird.conf'
```
Returns a hashtable of all active (non-commented) configuration entries.

### Update or Comment Out Configuration Entries
```powershell
Write-FirebirdConfiguration -Path 'C:/Firebird/firebird.conf' -Configuration @{ 'Key' = 'Value'; 'OtherKey' = $null }
```
Updates or adds the specified key/value pairs. Use `$null` to comment out a key.

## Contributing
Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request.

---
> For more information, see the [Firebird Project](https://firebirdsql.org/) and the inline help for each cmdlet.
