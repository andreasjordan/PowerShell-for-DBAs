@{
    DataTypes = @{
        INTEGER = @{
            SQLServer  = 'INT'
            Oracle     = 'NUMBER(10, 0)'
            PostgreSQL = 'INT'
            MySQL      = 'INT'
            Db2        = ''
            Informix   = ''
        }
        VARCHAR = @{
            SQLServer  = 'NVARCHAR'
            Oracle     = 'VARCHAR2'
            PostgreSQL = 'VARCHAR'
            MySQL      = 'VARCHAR'
            Db2        = ''
            Informix   = ''
        }
        VARCHAR_MAX = @{
            SQLServer  = 'VARCHAR(MAX)'
            Oracle     = 'CLOB'
            PostgreSQL = 'TEXT'
            MySQL      = 'TEXT'  # or CLOB?
            Db2        = ''
            Informix   = ''
        }
        TIMESTAMP = @{
            SQLServer  = 'DATETIME'
            Oracle     = 'TIMESTAMP(3)'
            PostgreSQL = 'TIMESTAMP(3)'
            MySQL      = 'TIMESTAMP(3)'
            Db2        = ''
            Informix   = ''
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
            IndexName  = 'badges_userid'
            Columns    = @( 'UserId' )
        }
        @{
            TableName  = 'Badges'
            IndexName  = 'badges_name'
            Columns    = @( 'Name' )
        }
        @{
            TableName  = 'comments'
            IndexName  = 'comments_postid'
            Columns    = @( 'postid' )
        }
        @{
            TableName  = 'comments'
            IndexName  = 'comments_score'
            Columns    = @( 'score' )
        }
        @{
            TableName  = 'comments'
            IndexName  = 'comments_userid'
            Columns    = @( 'userid' )
        }
        @{
            TableName  = 'posts'
            IndexName  = 'posts_owneruserid'
            Columns    = @( 'owneruserid' )
        }
        @{
            TableName  = 'posts'
            IndexName  = 'posts_score'
            Columns    = @( 'score' )
        }
        @{
            TableName  = 'users'
            IndexName  = 'users_location'
            Columns    = @( 'location' )
        }
        @{
            TableName  = 'users'
            IndexName  = 'users_reputation'
            Columns    = @( 'reputation' )
        }
        @{
            TableName  = 'votes'
            IndexName  = 'votes_postid'
            Columns    = @( 'postid' )
        }
        @{
            TableName  = 'votes'
            IndexName  = 'votes_userid'
            Columns    = @( 'userid' )
        }
    )
}
