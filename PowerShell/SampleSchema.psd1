@{
    DataTypes = @{
        INTEGER = @{
            SQLServer  = 'INT'
            Oracle     = 'NUMBER(10, 0)'
            PostgreSQL = 'INT'
            MySQL      = 'INT'
            Db2        = 'INT'
            Informix   = 'INT'
        }
        VARCHAR = @{
            SQLServer  = 'NVARCHAR'
            Oracle     = 'VARCHAR2'
            PostgreSQL = 'VARCHAR'
            MySQL      = 'VARCHAR'
            Db2        = 'VARCHAR'
            Informix   = 'LVARCHAR'
        }
        VARCHAR_MAX = @{
            SQLServer  = 'VARCHAR(MAX)'
            Oracle     = 'CLOB'
            PostgreSQL = 'TEXT'
            MySQL      = 'TEXT'  # or CLOB?
            Db2        = 'CLOB(2G)'
            Informix   = 'TEXT'  # CLOB does not work with the old Informix DLL
        }
        TIMESTAMP = @{
            SQLServer  = 'DATETIME'
            Oracle     = 'TIMESTAMP(3)'
            PostgreSQL = 'TIMESTAMP(3)'
            MySQL      = 'TIMESTAMP(3)'
            Db2        = 'TIMESTAMP'
            Informix   = 'DATETIME YEAR TO FRACTION'
        }
    }
    Tables = @(
        @{
            TableName  = 'Badges'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Name';                  Datatype = 'VARCHAR_40';  Constraint = 'NULL'     }
                @{  ColumnName = 'UserId';                Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'Comments'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'PostId';                Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Score';                 Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'Text';                  Datatype = 'VARCHAR_700'; Constraint = 'NULL'     }
                @{  ColumnName = 'UserId';                Datatype = 'INTEGER';     Constraint = 'NULL'     }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'LinkTypes'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Type';                  Datatype = 'VARCHAR_50';  Constraint = 'NULL'     }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'PostLinks'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'PostId';                Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'RelatedPostId';         Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'LinkTypeId';            Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'Posts'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'AcceptedAnswerId';      Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'AnswerCount';           Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'Body';                  Datatype = 'VARCHAR_MAX'; Constraint = 'NOT NULL' }
                @{  ColumnName = 'ClosedDate';            Datatype = 'TIMESTAMP';   Constraint = 'NULL'     }
                @{  ColumnName = 'CommentCount';          Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'CommunityOwnedDate';    Datatype = 'TIMESTAMP';   Constraint = 'NULL'     }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'FavoriteCount';         Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'LastActivityDate';      Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'LastEditDate';          Datatype = 'TIMESTAMP';   Constraint = 'NULL'     }
                @{  ColumnName = 'LastEditorDisplayName'; Datatype = 'VARCHAR_40';  Constraint = 'NULL'     }
                @{  ColumnName = 'LastEditorUserId';      Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'OwnerUserId';           Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'ParentId';              Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'PostTypeId';            Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Score';                 Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Tags';                  Datatype = 'VARCHAR_150'; Constraint = 'NULL'     }
                @{  ColumnName = 'Title';                 Datatype = 'VARCHAR_250'; Constraint = 'NULL'     }
                @{  ColumnName = 'ViewCount';             Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'PostTypes'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Type';                  Datatype = 'VARCHAR_50';  Constraint = 'NULL'     }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'Users'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'AboutMe';               Datatype = 'VARCHAR_MAX'; Constraint = 'NULL'     }
                @{  ColumnName = 'Age';                   Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'DisplayName';           Datatype = 'VARCHAR_40';  Constraint = 'NULL'     }
                @{  ColumnName = 'DownVotes';             Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'EmailHash';             Datatype = 'VARCHAR_40';  Constraint = 'NULL'     }
                @{  ColumnName = 'LastAccessDate';        Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
                @{  ColumnName = 'Location';              Datatype = 'VARCHAR_100'; Constraint = 'NULL'     }
                @{  ColumnName = 'Reputation';            Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'UpVotes';               Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Views';                 Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'WebsiteUrl';            Datatype = 'VARCHAR_200'; Constraint = 'NULL'     }
                @{  ColumnName = 'AccountId';             Datatype = 'INTEGER';     Constraint = 'NULL'     }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'Votes'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'PostId';                Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'UserId';                Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'BountyAmount';          Datatype = 'INTEGER';     Constraint = 'NULL'     }
                @{  ColumnName = 'VoteTypeId';            Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'CreationDate';          Datatype = 'TIMESTAMP';   Constraint = 'NOT NULL' }
            )
            PrimaryKey = 'Id'
        }
        @{
            TableName  = 'VoteTypes'
            Columns    = @(
                @{  ColumnName = 'Id';                    Datatype = 'INTEGER';     Constraint = 'NOT NULL' }
                @{  ColumnName = 'Name';                  Datatype = 'VARCHAR_50';  Constraint = 'NULL'     }
            )
            PrimaryKey = 'Id'
        }
    )
    Indexes = @(
        @{
            TableName  = 'Badges'
            IndexName  = 'Badges_UserId'
            Columns    = @( 'UserId' )
        }
        @{
            TableName  = 'Badges'
            IndexName  = 'Badges_Name'
            Columns    = @( 'Name' )
        }
        @{
            TableName  = 'Comments'
            IndexName  = 'Comments_PostId'
            Columns    = @( 'PostId' )
        }
        @{
            TableName  = 'Comments'
            IndexName  = 'Comments_Score'
            Columns    = @( 'Score' )
        }
        @{
            TableName  = 'Comments'
            IndexName  = 'Comments_UserId'
            Columns    = @( 'UserId' )
        }
        @{
            TableName  = 'Posts'
            IndexName  = 'Posts_OwnerUserId'
            Columns    = @( 'OwnerUserId' )
        }
        @{
            TableName  = 'Posts'
            IndexName  = 'Posts_Score'
            Columns    = @( 'Score' )
        }
        @{
            TableName  = 'Users'
            IndexName  = 'Users_Location'
            Columns    = @( 'Location' )
        }
        @{
            TableName  = 'Users'
            IndexName  = 'Users_Reputation'
            Columns    = @( 'Reputation' )
        }
        @{
            TableName  = 'Votes'
            IndexName  = 'Votes_PostId'
            Columns    = @( 'PostId' )
        }
        @{
            TableName  = 'Votes'
            IndexName  = 'Votes_UserId'
            Columns    = @( 'UserId' )
        }
    )
}
