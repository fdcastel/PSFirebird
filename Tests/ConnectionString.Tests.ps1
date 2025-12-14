Import-Module "$PSScriptRoot/../PSFirebird.psd1" -Force

Describe 'Split-FirebirdConnectionString' {
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
