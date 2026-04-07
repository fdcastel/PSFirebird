Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force
. "$PSScriptRoot/TestHelper.ps1"

Describe 'Get-FirebirdDatabaseStatistics' -Tag 'Integration' {
    BeforeAll {
        # Create a temporary folder for the test files
        $script:RootFolder = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name (New-Guid)

        $script:TestEnvironment = New-FirebirdEnvironment -Version $FirebirdVersion
        $script:TestDatabase = New-FirebirdDatabase -Database "$RootFolder/$FirebirdVersion-tests.fdb" -Environment $TestEnvironment

        # Set up the environment variables for Firebird
        $env:ISC_USER = 'SYSDBA'
        $env:ISC_PASSWORD = 'masterkey'

        # Create user tables for statistics tests
        Invoke-FirebirdIsql -Database $TestDatabase -Environment $TestEnvironment -Sql @'
CREATE TABLE CUSTOMERS (ID INTEGER NOT NULL, NAME VARCHAR(100), CONSTRAINT PK_CUSTOMERS PRIMARY KEY (ID));
CREATE TABLE ORDERS (ID INTEGER NOT NULL, CUSTOMER_ID INTEGER, AMOUNT DECIMAL(10,2), CONSTRAINT PK_ORDERS PRIMARY KEY (ID));
'@
    }

    AfterAll {
        # Remove the test folder
        Remove-Item -Path $RootFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Returns an object with tables and indices properties' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment

        $result | Should -Not -BeNull
        $result.tables | Should -Not -BeNull
        $result.indices | Should -Not -BeNull
    }

    It 'Returns tables as a non-empty collection' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment

        $result.tables.Count | Should -BeGreaterThan 0
    }

    It 'Returns indices as a non-empty collection' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment

        $result.indices.Count | Should -BeGreaterThan 0
    }

    It 'Includes user tables in results' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment

        $result.tables.TableName | Should -Contain 'CUSTOMERS'
        $result.tables.TableName | Should -Contain 'ORDERS'
    }

    It 'Includes primary key indices in results' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment

        $result.indices.IndexName | Should -Contain 'PK_CUSTOMERS'
        $result.indices.IndexName | Should -Contain 'PK_ORDERS'
    }

    It 'Filters tables using -TableName' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment -TableName 'CUSTOMERS'

        $result.tables.TableName | Should -Contain 'CUSTOMERS'
        $result.tables.TableName | Should -Not -Contain 'ORDERS'
    }

    It 'Filters indices to match -TableName tables' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment -TableName 'CUSTOMERS'

        $result.indices.IndexName | Should -Contain 'PK_CUSTOMERS'
        $result.indices.IndexName | Should -Not -Contain 'PK_ORDERS'
    }

    It 'Accepts multiple table names with -TableName' {
        $result = Get-FirebirdDatabaseStatistics -Database $TestDatabase -Environment $TestEnvironment -TableName 'CUSTOMERS', 'ORDERS'

        $result.tables.TableName | Should -Contain 'CUSTOMERS'
        $result.tables.TableName | Should -Contain 'ORDERS'
    }

    It 'Accepts pipeline input' {
        $result = $TestDatabase | Get-FirebirdDatabaseStatistics -Environment $TestEnvironment

        $result | Should -Not -BeNull
        $result.tables.TableName | Should -Contain 'CUSTOMERS'
    }

    It 'Throws when analyzing a non-existent database' {
        $fakeDb = [FirebirdDatabase]::new("$RootFolder/nonexistent.fdb")
        { Get-FirebirdDatabaseStatistics -Database $fakeDb -Environment $TestEnvironment } | Should -Throw
    }
}
