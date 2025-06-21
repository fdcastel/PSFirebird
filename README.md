# PSFirebird

<img src="docs/PSFirebird-logo.png" alt="PSFirebird Logo" width="180" align="right" />

A PowerShell module for managing Firebird database environments, databases, and utilities on Windows and Linux.

### Features

- Download and run multiple Firebird embedded environments without installation.
- Create and inspect Firebird databases.
- Run SQL scripts and queries using Firebird's `isql` utility.
- Backup and restore Firebird databases.
- Convert databases between Firebird versions using high-speed backup/restore streaming.
- Read and write Firebird configuration files.

### Requirements

- PowerShell 7.4 or later
- Windows or Linux (Debian-based for Linux)

### Installation

Run the following command to install this package using [PowerShellGet](https://www.powershellgallery.com/packages/PSFirebird/):

```powershell
Install-Module -Name PSFirebird
```



# Usage

### Command summary

| Command                                                    | Description                                        |
|------------------------------------------------------------|-----------------------------------------------------------|
| [New-FirebirdEnvironment](#new-firebirdenvironment)        | Download and set up a Firebird environment.               |
| [Get-FirebirdEnvironment](#get-firebirdenvironment)        | Get information about a Firebird environment.             |
| [Use-FirebirdEnvironment](#use-firebirdenvironment)        | Set the default Firebird environment for a given context. |
| | |
| [New-FirebirdDatabase](#new-firebirddatabase)              | Create a new Firebird database.                   |
| [Get-FirebirdDatabase](#get-firebirddatabase)              | Get information about a Firebird database.        |
| [Read-FirebirdDatabase](#read-firebirddatabase)            | Read detailed info from a Firebird database.      |
| [Invoke-FirebirdIsql](#invoke-firebirdisql)                | Execute SQL statements using Firebird `isql`.       |
| | |
| [Read-FirebirdConfiguration](#read-firebirdconfiguration)  | Read settings from a Firebird configuration file.        |
| [Write-FirebirdConfiguration](#write-firebirdconfiguration)| Update settings in a Firebird configuration file.        |
| | |
| [Backup-FirebirdDatabase](#backup-firebirddatabase)        | Create a backup file from a Firebird database. |
| [Restore-FirebirdDatabase](#restore-firebirddatabase)      | Restore a Firebird database from a backup file.    |
| [Convert-FirebirdDatabase](#convert-firebirddatabase)      | Perform backup and restore operations using streaming. |




## Environment commands

### New-FirebirdEnvironment

_Download and set up a Firebird environment._

```
New-FirebirdEnvironment -Version <semver> [-Path <string>] [-RuntimeIdentifier <string>] [-Force] [<CommonParameters>]
```

Downloads and extracts the specified Firebird version to a directory. 

If no path is given, a temporary directory is used. 

Use `-Force` to overwrite an existing environment.

```powershell
# Example: Download Firebird 5.0.2 to a custom path
New-FirebirdEnvironment -Version '5.0.2' -Path '/opt/firebird-5.0.2' -Force
```

---

### Get-FirebirdEnvironment

_Get information about a Firebird environment._

```
Get-FirebirdEnvironment -Path <string> [<CommonParameters>]
```

Returns a `FirebirdEnvironment` object with details about the specified or current environment.

```powershell
# Example: Get environment info for a specific path
Get-FirebirdEnvironment -Path '/opt/firebird-5.0.2'
```

---

### Use-FirebirdEnvironment

_Set the default Firebird environment for a given context._

```
Use-FirebirdEnvironment -Environment <FirebirdEnvironment> -ScriptBlock <scriptblock> [<CommonParameters>]
```

Temporarily sets the default Firebird environment for all commands executed within the provided script block.

```powershell
# Example: Use a specific environment for a set of commands
Use-FirebirdEnvironment -Environment $fbEnv -ScriptBlock {
    New-FirebirdDatabase -Database 'test.fdb'
    Backup-FirebirdDatabase -Database 'test.fdb' -BackupFilePath 'backup.fbk'
}
```

---

## Database commands

### New-FirebirdDatabase

_Create a new Firebird database._

```
New-FirebirdDatabase -Database <string> [-User <string>] [-Password <string>] [-PageSize <int>] [-Charset <string>] [-Environment <FirebirdEnvironment>] [-Force] [<CommonParameters>]
```

Creates a new Firebird database file. Use `-Force` to overwrite an existing file. You can specify user, password, page size, and charset.

```powershell
# Example: Create a new database with custom options
New-FirebirdDatabase -Database '/data/newdb.fdb' -User 'SYSDBA' -Password 'masterkey' -PageSize 8192 -Charset 'UTF8'
```

---

### Get-FirebirdDatabase

_Get information about a Firebird database._

```
Get-FirebirdDatabase -Path <string> [-Environment <FirebirdEnvironment>] [<CommonParameters>]
```

Returns a `FirebirdDatabase` object with details such as environment, page size, and ODS version.

```powershell
# Example: Get database info
Get-FirebirdDatabase -Path '/data/mydb.fdb'
```

---

### Read-FirebirdDatabase

_Read detailed info from a Firebird database._

```
Read-FirebirdDatabase -Database <string> [-Environment <FirebirdEnvironment>] [<CommonParameters>]
```

Reads and returns properties from `MON$DATABASE` and `RDB$DATABASE` for the specified database.

```powershell
# Example: Read database properties
Read-FirebirdDatabase -Database '/data/mydb.fdb'
```

---

### Invoke-FirebirdIsql

_Execute SQL statements using Firebird `isql`._

```
Invoke-FirebirdIsql -Database <FirebirdDatabase> -Sql <string> [-Environment <FirebirdEnvironment>] [<CommonParameters>]
```

Executes SQL statements against a Firebird database using the `isql` utility. Accepts SQL from the pipeline.

```powershell
# Example: Run a SQL query
Invoke-FirebirdIsql -Database '/data/mydb.fdb' -Sql 'SELECT * FROM RDB$DATABASE;'

# Example: Using pipeline input
'SELECT COUNT(*) FROM MY_TABLE;' | Invoke-FirebirdIsql -Database '/data/mydb.fdb'
```

---

## Configuration commands

### Read-FirebirdConfiguration

_Read settings from a Firebird configuration file._

```
Read-FirebirdConfiguration -Path <string> [<CommonParameters>]
```

Reads all active (non-commented) configuration entries from a Firebird config file and returns them as a hashtable.

```powershell
# Example: Read configuration
Read-FirebirdConfiguration -Path '/opt/firebird/firebird.conf'
```

---

### Write-FirebirdConfiguration

_Update settings in a Firebird configuration file._

```
Write-FirebirdConfiguration -Path <string> -Configuration <hashtable> [<CommonParameters>]
```

Updates, adds, or comments out configuration entries in the file based on the provided hashtable. Use `$null` as a value to comment out a key.

```powershell
# Example: Update a configuration value
Write-FirebirdConfiguration -Path '/opt/firebird/firebird.conf' -Configuration @{ 'Key' = 'Value' }

# Example: Comment out a configuration key
Write-FirebirdConfiguration -Path '/opt/firebird/firebird.conf' -Configuration @{ 'Key' = $null }
```



## Backup and restore commands

### ⚠️ Caution when restoring databases

> **Do not use `-Force` option with production databases.**
>
> This option exists for convenience in test scenarios only. **Never overwrite a production database** since a failure in the process (e.g., due to a corrupt backup) may cause a potential data loss.

Always restore a backup to a _different_ database file. The `Restore-FirebirdDatabase` command’s default behavior of appending a `.restore` suffix when no database file is specified is a good practice.



### Backup-FirebirdDatabase

_Create a backup file from a Firebird database._

```
Backup-FirebirdDatabase [-Database] <FirebirdDatabase> [[-BackupFilePath] <String>] [-Environment <FirebirdEnvironment>] [-Force] [-Transportable] [-RemainingArguments <Object>] [<CommonParameters>]
Backup-FirebirdDatabase [-Database] <FirebirdDatabase> -AsCommandLine [-Environment <FirebirdEnvironment>] [-Force] [-Transportable] [-RemainingArguments <Object>] [<CommonParameters>]
```


Use `-Database` to specify the source database, and `-BackupFilePath` to define the target backup file. If not specified, the backup file defaults to the database name with a `.fbk` extension.

The `-AsCommandLine` option outputs a `gbak` command line equivalent for the same operation.

The backup file must not already exist. Use the `-Force` option to overwrite it if necessary.

By default, all backups are created as *non-transportable*, resulting in approximately 5% faster performance. Use the `-Transportable` option if you plan to restore the database on a different system.

```powershell
# Example: Create a transportable backup.
Backup-FirebirdDatabase -Database '/data/mydb.fdb' -BackupFile '/backups/mydb.fbk' -Transportable
```



### Restore-FirebirdDatabase

_Restore a Firebird database from a backup file._

```
Restore-FirebirdDatabase [-BackupFilePath] <string> [[-Database] <FirebirdDatabase>] [-Environment <FirebirdEnvironment>] [-Force] [-RemainingArguments <Object>] [<CommonParameters>]
Restore-FirebirdDatabase -AsCommandLine -Database <FirebirdDatabase> [-Environment <FirebirdEnvironment>] [-Force] [-RemainingArguments <Object>] [<CommonParameters>]
```

Use `-BackupFilePath` to specify the source backup file, and `-Database` to define the target database. If not specified, the database defaults to the backup file name with a `.restored.fdb` extension.

The `-AsCommandLine` option outputs a `gbak` command line equivalent for the same operation. In this case you must specify a `-Database` to restore to.

The database must not already exist. Use the `-Force` ⚠️ option to overwrite it if necessary.



```powershell
# Example: restore a Firebird database from backup.
Restore-FirebirdDatabase -BackupFile '/backups/mydb.fbk' -Database '/data/mydb.restored.fdb'
```



### Convert-FirebirdDatabase

_Perform backup and restore operations using streaming._

```
Convert-FirebirdDatabase -SourceDatabase <string> -TargetDatabase <string> [-SourceEnvironment <FirebirdEnvironment>] [-TargetEnvironment <FirebirdEnvironment>] [-Force] [<CommonParameters>]
```

Start two `gbak` instances (one to perform the backup and the other to restore) by piping the output of the first directly into the second. This enables a full backup/restore cycle without creating intermediate files.

Use this when migrating across major Firebird versions (with different On-Disk-Structure formats) or during routine maintenance by performing a full backup and restore in the same version.

The target database must not already exist. Use the `-Force` ⚠️ option to overwrite it if necessary.

```powershell
# Example: Convert a Firebird database from v3 to v5
$fb3 = New-FirebirdEnvironment -Version '3.0.12'
$fb5 = New-FirebirdEnvironment -Version '5.0.2'

Convert-FirebirdDatabase -SourceDatabase '/data/mydb3.fdb' `
                         -SourceEnvironment $fb3 `
                         -TargetDatabase '/data/mydb5.fdb' `
                         -TargetEnvironment $fb4
```



# Development notes

- Keep one function per file, unless the functions are closely related.
- Include verbose messages that may help with future debugging.
  - Just the minimum necessary for a useful debugging analysis.
  - Always use the `Write-VerboseMark` function to produce verbose messages. This adds a quick link to the source of the message.
- Ensure all conditional and loop statements include a `Write-VerboseMark` call to output appropriate messages for debugging.
  - This ensures better traceability of conditional logic during execution.
  - Skip this rule for guard statements (`if` statements that ONLY throw an exception for a given condition)



## Testing

Run the included Pester (v5+) tests:

```powershell
Invoke-Pester
```



## Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request.
