# PSFirebird

<img src="docs/PSFirebird-logo.png" alt="PSFirebird Logo" width="180" align="right" />

PowerShell toolkit for Firebird databases.

🚧 **Under Construction** 🚧

### Features (for now)

- Download and installs multiple Firebird Embedded environments for Windows and Linux
- Create new Firebird databases with custom options

## Installation

Clone this repository and import the module:

```powershell
Import-Module ./PSFirebird.psd1 -Force
```

## Usage

### Install a Firebird Environment

```powershell
$fbEnv = Install-FirebirdEnvironment -Version 5.0.2 -Verbose
```
- Use `-Path` to specify a custom output directory
- Use `-Force` to overwrite existing output

### Get Firebird Environment Information

```powershell
Get-FirebirdEnvironment $fbEnv
```
- Returns a `FirebirdEnvironment` with `Path` and `Version`

### Create a New Database

```powershell
New-FirebirdDatabase -DatabasePath '/tmp/test.fdb' -Environment $fbEnv -Force
```
- Supports `-User`, `-Password`, `-PageSize`, `-Charset`, and `-Force`
- Returns a PSCustomObject with database details

## Public Functions

- `Install-FirebirdEnvironment`: Download and extract Firebird packages
- `Get-FirebirdEnvironment`: Inspect a Firebird environment
- `New-FirebirdDatabase`: Create a new Firebird database

## Requirements

- PowerShell 7.4 or later
- Windows or Linux (Debian-based for Linux)

---
> For more information, see the [Firebird Project](https://firebirdsql.org/)
