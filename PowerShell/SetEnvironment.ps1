param(
    [Parameter(Mandatory)][ValidateSet("MDBC01", "Docker")][string]$Client,
    [Parameter(Mandatory)][ValidateSet("MDBW02", "Docker", "TestA")][string]$Server
)
$ErrorActionPreference = 'Stop'

switch ($Client) {
    "MDBC01" {
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $Env:ORACLE_DLL = 'C:\NuGet\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll'
            #$Env:ORACLE_DLL = 'C:\oracle\product\19.0.0\client_1\odp.net\managed\common\Oracle.ManagedDataAccess.dll'
            $Env:MYSQL_DLL = 'C:\NuGet\MySql.Data\lib\net452\MySql.Data.dll'
            $Env:POSTGRESQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
        } else {
            $Env:ORACLE_DLL = 'C:\NuGet\Oracle.ManagedDataAccess.Core\lib\netstandard2.1\Oracle.ManagedDataAccess.dll'
            $Env:MYSQL_DLL = 'C:\NuGet\MySql.Data\lib\net6.0\MySql.Data.dll'
            $Env:POSTGRESQL_DLL = 'C:\NuGet\Npgsql\lib\net6.0\Npgsql.dll'
            $Env:DB2_DLL = 'C:\NuGet\Net.IBM.Data.Db2\lib\net6.0\IBM.Data.Db2.dll'
            $Env:INFORMIX_DLL = 'C:\NuGet\Net.IBM.Data.Db2\lib\net6.0\IBM.Data.Db2.dll'
        }
    }

    "Docker" {
        $Env:ORACLE_DLL = '/mnt/NuGet/Oracle.ManagedDataAccess.Core/lib/netstandard2.1/Oracle.ManagedDataAccess.dll'
        $Env:MYSQL_DLL = '/mnt/NuGet/MySql.Data/lib/net6.0/MySql.Data.dll'
        $Env:POSTGRESQL_DLL = '/mnt/NuGet/Npgsql/lib/net6.0/Npgsql.dll'
        $Env:DB2_DLL = '/mnt/NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll'
        $Env:INFORMIX_DLL = '/mnt/NuGet/Net.IBM.Data.Db2-lnx/lib/net6.0/IBM.Data.Db2.dll'
    }
}

switch ($Server) {
    "MDBW02" {
        $Env:SQLSERVER_INSTANCE = 'MDBW02\SQLEXPRESS'
        $Env:SQLSERVER_DATABASE = 'StackOverflow'
        $Env:SQLSERVER_USERNAME = 'StackOverflow'
        $Env:SQLSERVER_PASSWORD = 'start456'

        $Env:ORACLE_INSTANCE = 'MDBW02/XEPDB1'
        $Env:ORACLE_USERNAME = 'stackoverflow'
        $Env:ORACLE_PASSWORD = 'start456'

        $Env:MYSQL_INSTANCE = 'MDBW02'
        $Env:MYSQL_DATABASE = 'stackoverflow'
        $Env:MYSQL_USERNAME = 'stackoverflow'
        $Env:MYSQL_PASSWORD = 'start456'

        $Env:POSTGRESQL_INSTANCE = 'MDBW02'
        $Env:POSTGRESQL_DATABASE = 'stackoverflow'
        $Env:POSTGRESQL_USERNAME = 'stackoverflow'
        $Env:POSTGRESQL_PASSWORD = 'start456'

        $Env:DB2_INSTANCE = 'MDBW02:25000'
        $Env:DB2_DATABASE = 'SAMPLE'
        $Env:DB2_USERNAME = 'ORDIX\stackoverflow'
        $Env:DB2_PASSWORD = 'start456'

        $Env:INFORMIX_INSTANCE = 'MDBW02:9089'  # When used with Db2 client
        #$Env:INFORMIX_INSTANCE = 'MDBW02:9088:ol_informix1410'  # When used with Informix client
        $Env:INFORMIX_DATABASE = 'stackoverflow'
        $Env:INFORMIX_USERNAME = 'ORDIX\stackoverflow'
        $Env:INFORMIX_PASSWORD = 'start456'
    }

    "Docker" {
        $Env:SQLSERVER_INSTANCE = 'SQLServer-1'
        $Env:SQLSERVER_DATABASE = 'StackOverflow'
        $Env:SQLSERVER_USERNAME = 'StackOverflow'
        $Env:SQLSERVER_PASSWORD = 'start456'

        $Env:ORACLE_INSTANCE = 'Oracle-1/XEPDB1'
        $Env:ORACLE_USERNAME = 'stackoverflow'
        $Env:ORACLE_PASSWORD = 'start456'

        $Env:MYSQL_INSTANCE = 'MySQL-1'
        $Env:MYSQL_DATABASE = 'stackoverflow'
        $Env:MYSQL_USERNAME = 'stackoverflow'
        $Env:MYSQL_PASSWORD = 'start456'

        $Env:POSTGRESQL_INSTANCE = 'PostgreSQL-1'
        $Env:POSTGRESQL_DATABASE = 'stackoverflow'
        $Env:POSTGRESQL_USERNAME = 'stackoverflow'
        $Env:POSTGRESQL_PASSWORD = 'start456'

        $Env:DB2_INSTANCE = 'Db2-1:50000'
        $Env:DB2_DATABASE = 'DEMO'
        $Env:DB2_USERNAME = 'stackoverflow'
        $Env:DB2_PASSWORD = 'start456'

        $Env:INFORMIX_INSTANCE = 'Informix-1:9089'
        $Env:INFORMIX_DATABASE = 'stackoverflow'
        $Env:INFORMIX_USERNAME = 'stackoverflow'
        $Env:INFORMIX_PASSWORD = 'start456'
    }

    "TestA" {
        $Env:SQLSERVER_INSTANCE = '172.20.170.137'
        $Env:SQLSERVER_DATABASE = 'StackOverflow'
        $Env:SQLSERVER_USERNAME = 'StackOverflow'
        $Env:SQLSERVER_PASSWORD = 'start456'

        $Env:ORACLE_INSTANCE = '172.20.170.137/XEPDB1'
        $Env:ORACLE_USERNAME = 'stackoverflow'
        $Env:ORACLE_PASSWORD = 'start456'

        $Env:MYSQL_INSTANCE = '172.20.170.137'
        $Env:MYSQL_DATABASE = 'stackoverflow'
        $Env:MYSQL_USERNAME = 'stackoverflow'
        $Env:MYSQL_PASSWORD = 'start456'

        $Env:POSTGRESQL_INSTANCE = '172.20.170.137'
        $Env:POSTGRESQL_DATABASE = 'stackoverflow'
        $Env:POSTGRESQL_USERNAME = 'stackoverflow'
        $Env:POSTGRESQL_PASSWORD = 'start456'

        $Env:DB2_INSTANCE = '172.20.170.137:50000'
        $Env:DB2_DATABASE = 'DEMO'
        $Env:DB2_USERNAME = 'stackoverflow'
        $Env:DB2_PASSWORD = 'start456'

        $Env:INFORMIX_INSTANCE = '172.20.170.137:9089'
        $Env:INFORMIX_DATABASE = 'stackoverflow'
        $Env:INFORMIX_USERNAME = 'stackoverflow'
        $Env:INFORMIX_PASSWORD = 'start456'
    }
}
