Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Split-FirebirdConnectionString' -Tag 'Unit' {
    InModuleScope 'PSFirebird' {

        # Source: https://firebirdsql.org/file/documentation/html/en/firebirddocs/qsg5/firebird-5-quickstartguide.html#qsg5-databases-connstrings

        It 'parses /opt/firebird/examples/empbuild/employee.fdb' {
            $r = Split-FirebirdConnectionString '/opt/firebird/examples/empbuild/employee.fdb'
            $r.Protocol | Should -Be $null
            $r.Host | Should -Be $null
            $r.Port | Should -Be $null
            $r.Path | Should -Be '/opt/firebird/examples/empbuild/employee.fdb'
        }

        It 'parses C:\Biology\Data\Primates\Apes\populations.fdb' {
            $r = Split-FirebirdConnectionString 'C:\Biology\Data\Primates\Apes\populations.fdb'
            $r.Protocol | Should -Be $null
            $r.Host | Should -Be $null
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'C:\Biology\Data\Primates\Apes\populations.fdb'
        }

        It 'parses xnet://security.db' {
            $r = Split-FirebirdConnectionString 'xnet://security.db'
            $r.Protocol | Should -Be 'xnet'
            $r.Host | Should -Be $null
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'security.db'
        }

        It 'parses xnet://C:\Programmas\Firebird\Firebird_3_0\security3.fdb' {
            $r = Split-FirebirdConnectionString 'xnet://C:\Programmas\Firebird\Firebird_3_0\security3.fdb'
            $r.Protocol | Should -Be 'xnet'
            $r.Host | Should -Be $null
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'C:\Programmas\Firebird\Firebird_3_0\security3.fdb'
        }

        It 'parses pongo:/opt/firebird/examples/empbuild/employee.fdb' {
            $r = Split-FirebirdConnectionString 'pongo:/opt/firebird/examples/empbuild/employee.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'pongo'
            $r.Port | Should -Be $null
            $r.Path | Should -Be '/opt/firebird/examples/empbuild/employee.fdb'
        }
        It 'parses inet://pongo//opt/firebird/examples/empbuild/employee.fdb' {
            $r = Split-FirebirdConnectionString 'inet://pongo//opt/firebird/examples/empbuild/employee.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'pongo'
            $r.Port | Should -Be $null
            $r.Path | Should -Be '/opt/firebird/examples/empbuild/employee.fdb'
        }
        It 'parses bongo/3052:fury' {
            $r = Split-FirebirdConnectionString 'bongo/3052:fury'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'bongo'
            $r.Port | Should -Be '3052'
            $r.Path | Should -Be 'fury'
        }
        It 'parses inet://bongo:3052/fury' {
            $r = Split-FirebirdConnectionString 'inet://bongo:3052/fury'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'bongo'
            $r.Port | Should -Be '3052'
            $r.Path | Should -Be 'fury'
        }
        It 'parses 112.179.0.1:/var/Firebird/databases/butterflies.fdb' {
            $r = Split-FirebirdConnectionString '112.179.0.1:/var/Firebird/databases/butterflies.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be '112.179.0.1'
            $r.Port | Should -Be $null
            $r.Path | Should -Be '/var/Firebird/databases/butterflies.fdb'
        }
        It 'parses inet://112.179.0.1//var/Firebird/databases/butterflies.fdb' {
            $r = Split-FirebirdConnectionString 'inet://112.179.0.1//var/Firebird/databases/butterflies.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be '112.179.0.1'
            $r.Port | Should -Be $null
            $r.Path | Should -Be '/var/Firebird/databases/butterflies.fdb'
        }
        It 'parses localhost:blackjack.fdb' {
            $r = Split-FirebirdConnectionString 'localhost:blackjack.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'localhost'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'blackjack.fdb'
        }
        It 'parses inet://localhost/blackjack.fdb' {
            $r = Split-FirebirdConnectionString 'inet://localhost/blackjack.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'localhost'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'blackjack.fdb'
        }
        It 'parses siamang:C:\Biology\Data\Primates\Apes\populations.fdb' {
            $r = Split-FirebirdConnectionString 'siamang:C:\Biology\Data\Primates\Apes\populations.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'siamang'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'C:\Biology\Data\Primates\Apes\populations.fdb'
        }
        It 'parses inet://siamang/C:\Biology\Data\Primates\Apes\populations.fdb' {
            $r = Split-FirebirdConnectionString 'inet://siamang/C:\Biology\Data\Primates\Apes\populations.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'siamang'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'C:\Biology\Data\Primates\Apes\populations.fdb'
        }
        It 'parses sofa:D:\Misc\Friends\Rich\Lenders.fdb' {
            $r = Split-FirebirdConnectionString 'sofa:D:\Misc\Friends\Rich\Lenders.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'sofa'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'D:\Misc\Friends\Rich\Lenders.fdb'
        }
        It 'parses inet://sofa/D:\Misc\Friends\Rich\Lenders.fdb' {
            $r = Split-FirebirdConnectionString 'inet://sofa/D:\Misc\Friends\Rich\Lenders.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'sofa'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'D:\Misc\Friends\Rich\Lenders.fdb'
        }
        It 'parses inca/fb_db:D:\Traffic\Roads.fdb' {
            $r = Split-FirebirdConnectionString 'inca/fb_db:D:\Traffic\Roads.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'inca'
            $r.Port | Should -Be 'fb_db'
            $r.Path | Should -Be 'D:\Traffic\Roads.fdb'
        }
        It 'parses inet://inca:fb_db/D:\Traffic\Roads.fdb' {
            $r = Split-FirebirdConnectionString 'inet://inca:fb_db/D:\Traffic\Roads.fdb'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be 'inca'
            $r.Port | Should -Be 'fb_db'
            $r.Path | Should -Be 'D:\Traffic\Roads.fdb'
        }
        It 'parses 127.0.0.1:Borrowers' {
            $r = Split-FirebirdConnectionString '127.0.0.1:Borrowers'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be '127.0.0.1'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'Borrowers'
        }
        It 'parses inet://127.0.0.1/Borrowers' {
            $r = Split-FirebirdConnectionString 'inet://127.0.0.1/Borrowers'
            $r.Protocol | Should -Be 'inet'
            $r.Host | Should -Be '127.0.0.1'
            $r.Port | Should -Be $null
            $r.Path | Should -Be 'Borrowers'
        }
    }
}

Describe 'FirebirdDatabase' -Tag 'Unit' {

    Context 'Constructor and properties' {

        It 'constructs from local Linux path' {
            $db = [FirebirdDatabase]::new('/opt/firebird/db.fdb')
            $db.Protocol | Should -BeNullOrEmpty
            $db.Host | Should -BeNullOrEmpty
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be '/opt/firebird/db.fdb'
        }

        It 'constructs from local Windows path' {
            $db = [FirebirdDatabase]::new('C:\data\test.fdb')
            $db.Protocol | Should -BeNullOrEmpty
            $db.Host | Should -BeNullOrEmpty
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be 'C:\data\test.fdb'
        }

        It 'constructs from xnet connection' {
            $db = [FirebirdDatabase]::new('xnet://security.db')
            $db.Protocol | Should -Be 'xnet'
            $db.Host | Should -BeNullOrEmpty
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be 'security.db'
        }

        It 'constructs from legacy host:path' {
            $db = [FirebirdDatabase]::new('myserver:/opt/db.fdb')
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'myserver'
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be '/opt/db.fdb'
        }

        It 'constructs from legacy host/port:path' {
            $db = [FirebirdDatabase]::new('myserver/3051:/opt/db.fdb')
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'myserver'
            $db.Port | Should -Be '3051'
            $db.Path | Should -Be '/opt/db.fdb'
        }

        It 'constructs from legacy host with service-name port' {
            $db = [FirebirdDatabase]::new('inca/fb_db:D:\Traffic\Roads.fdb')
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'inca'
            $db.Port | Should -Be 'fb_db'
            $db.Path | Should -Be 'D:\Traffic\Roads.fdb'
        }

        It 'constructs from inet://host/path' {
            $db = [FirebirdDatabase]::new('inet://pongo//opt/db.fdb')
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'pongo'
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be '/opt/db.fdb'
        }

        It 'constructs from inet://host:port/path' {
            $db = [FirebirdDatabase]::new('inet://bongo:3052/fury')
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'bongo'
            $db.Port | Should -Be '3052'
            $db.Path | Should -Be 'fury'
        }

        It 'constructs from inet6://[::1]/path' {
            $db = [FirebirdDatabase]::new('inet6://[::1]/mydb.fdb')
            $db.Protocol | Should -Be 'inet6'
            $db.Host | Should -Be '::1'
            $db.Port | Should -BeNullOrEmpty
            $db.Path | Should -Be 'mydb.fdb'
        }

        It 'constructs from inet4://host:port/path' {
            $db = [FirebirdDatabase]::new('inet4://myserver:3051/mydb.fdb')
            $db.Protocol | Should -Be 'inet4'
            $db.Host | Should -Be 'myserver'
            $db.Port | Should -Be '3051'
            $db.Path | Should -Be 'mydb.fdb'
        }

        It 'constructs from hashtable' {
            $db = [FirebirdDatabase]::new(@{
                Protocol = 'inet'
                Host     = 'server1'
                Port     = '3055'
                Path     = '/data/test.fdb'
            })
            $db.Protocol | Should -Be 'inet'
            $db.Host | Should -Be 'server1'
            $db.Port | Should -Be '3055'
            $db.Path | Should -Be '/data/test.fdb'
        }
    }

    Context 'IsLocal' {

        It 'returns true for local path' {
            $db = [FirebirdDatabase]::new('/opt/db.fdb')
            $db.IsLocal() | Should -BeTrue
        }

        It 'returns true for xnet connection' {
            $db = [FirebirdDatabase]::new('xnet://security.db')
            $db.IsLocal() | Should -BeTrue
        }

        It 'returns false for remote connection' {
            $db = [FirebirdDatabase]::new('myserver:/opt/db.fdb')
            $db.IsLocal() | Should -BeFalse
        }

        It 'returns false for inet6 connection' {
            $db = [FirebirdDatabase]::new('inet6://[::1]/mydb.fdb')
            $db.IsLocal() | Should -BeFalse
        }
    }

    Context 'PortNumber' {

        It 'returns integer for numeric port' {
            $db = [FirebirdDatabase]::new('myserver/3051:/opt/db.fdb')
            $db.PortNumber() | Should -Be 3051
            $db.PortNumber() | Should -BeOfType [int]
        }

        It 'returns null for service-name port' {
            $db = [FirebirdDatabase]::new('inca/fb_db:D:\Traffic\Roads.fdb')
            $db.PortNumber() | Should -BeNull
        }

        It 'returns null when no port specified' {
            $db = [FirebirdDatabase]::new('/opt/db.fdb')
            $db.PortNumber() | Should -BeNull
        }
    }

    Context 'ConnectionString round-trip' {

        It 'round-trips local Linux path' {
            $db = [FirebirdDatabase]::new('/opt/db.fdb')
            $db.ConnectionString() | Should -Be '/opt/db.fdb'
        }

        It 'round-trips local Windows path' {
            $db = [FirebirdDatabase]::new('C:\data\test.fdb')
            $db.ConnectionString() | Should -Be 'C:\data\test.fdb'
        }

        It 'round-trips xnet connection' {
            $db = [FirebirdDatabase]::new('xnet://security.db')
            $db.ConnectionString() | Should -Be 'xnet://security.db'
        }

        It 'round-trips xnet with Windows path' {
            $db = [FirebirdDatabase]::new('xnet://C:\Programmas\Firebird\security3.fdb')
            $db.ConnectionString() | Should -Be 'xnet://C:\Programmas\Firebird\security3.fdb'
        }

        It 'round-trips legacy host:path' {
            $db = [FirebirdDatabase]::new('myserver:/opt/db.fdb')
            $db.ConnectionString() | Should -Be 'myserver:/opt/db.fdb'
        }

        It 'round-trips legacy host/port:path' {
            $db = [FirebirdDatabase]::new('myserver/3051:/opt/db.fdb')
            $db.ConnectionString() | Should -Be 'myserver/3051:/opt/db.fdb'
        }

        It 'round-trips legacy host with service-name port' {
            $db = [FirebirdDatabase]::new('inca/fb_db:D:\Traffic\Roads.fdb')
            $db.ConnectionString() | Should -Be 'inca/fb_db:D:\Traffic\Roads.fdb'
        }

        It 'normalizes inet:// to legacy format' {
            $db = [FirebirdDatabase]::new('inet://pongo//opt/db.fdb')
            $db.ConnectionString() | Should -Be 'pongo:/opt/db.fdb'
        }

        It 'normalizes inet://host:port to legacy format' {
            $db = [FirebirdDatabase]::new('inet://bongo:3052/fury')
            $db.ConnectionString() | Should -Be 'bongo/3052:fury'
        }

        It 'round-trips inet6 with IPv6 address' {
            $db = [FirebirdDatabase]::new('inet6://[::1]/mydb.fdb')
            $db.ConnectionString() | Should -Be 'inet6://[::1]/mydb.fdb'
        }

        It 'round-trips inet4 with port' {
            $db = [FirebirdDatabase]::new('inet4://myserver:3051/mydb.fdb')
            $db.ConnectionString() | Should -Be 'inet4://myserver:3051/mydb.fdb'
        }

        It 'round-trips inet4 without port' {
            $db = [FirebirdDatabase]::new('inet4://myserver/mydb.fdb')
            $db.ConnectionString() | Should -Be 'inet4://myserver/mydb.fdb'
        }

        It 'round-trips IP address with path' {
            $db = [FirebirdDatabase]::new('112.179.0.1:/var/db/butterflies.fdb')
            $db.ConnectionString() | Should -Be '112.179.0.1:/var/db/butterflies.fdb'
        }

        It 'round-trips alias via localhost' {
            $db = [FirebirdDatabase]::new('127.0.0.1:Borrowers')
            $db.ConnectionString() | Should -Be '127.0.0.1:Borrowers'
        }
    }

    Context 'ToString' {

        It 'includes Remote for remote databases' {
            $db = [FirebirdDatabase]::new('myserver:/opt/db.fdb')
            $db.ToString() | Should -Match 'Remote'
        }

        It 'includes Local for local databases' {
            $db = [FirebirdDatabase]::new('/opt/db.fdb')
            $db.ToString() | Should -Match 'Local'
        }
    }
}
