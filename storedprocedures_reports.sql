CREATE PROCEDURE sp_GetDynamicPersonnelReport
    @MonthsBack INT = 1,
    @ExcludeAttributes NVARCHAR(MAX) = NULL,  -- list of attributes to exclude (separate with comma)
    @Conditions NVARCHAR(MAX) = NULL  -- conditions ( in JSON format like below samples ) 
    /*
    sample JSON format:
    [
        {
            "attribute": "age",
            "operator": ">",
            "value": "50"
        },
        {
            "attribute": "gender",
            "operator": "=",
            "value": "male"
        }
    ]
    */
AS
BEGIN
    SET NOCOUNT ON;

    -- temp table for conditions
    CREATE TABLE #Conditions (
        AttributeName NVARCHAR(50),
        Operator NVARCHAR(10),
        Value NVARCHAR(MAX)
    );

    -- Parse JSON conditions if provided
    IF @Conditions IS NOT NULL
    BEGIN
        INSERT INTO #Conditions
        SELECT 
            JSON_VALUE(value, '$.attribute'),
            JSON_VALUE(value, '$.operator'),
            JSON_VALUE(value, '$.value')
        FROM OPENJSON(@Conditions);
    END

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @WhereClause NVARCHAR(MAX) = '';

    -- Build WHERE clause from conditions
    SELECT @WhereClause = @WhereClause + 
        CASE 
            WHEN @WhereClause = '' THEN 'WHERE '
            ELSE ' AND '
        END +
        'EXISTS (
            SELECT 1 
            FROM AttributeValues av2 
            JOIN Attributes a2 ON av2.AttributeID = a2.AttributeID
            WHERE av2.PersonnelID = p.PersonnelID 
            AND a2.AttributeName = ''' + AttributeName + '''
            AND av2.AttributeValue ' + Operator + ' ''' + Value + '''
        )'
    FROM #Conditions;

    -- Get dynamic column list excluding specified attributes
    WITH AttributeList AS (
        SELECT DISTINCT 
            AttributeName,
            '[' + AttributeName + ']' AS ColumnName
        FROM Attributes a
        WHERE (@ExcludeAttributes IS NULL 
            OR AttributeName NOT IN (
                SELECT value 
                FROM STRING_SPLIT(@ExcludeAttributes, ',')
            ))
    )
    SELECT @Columns = STRING_AGG(ColumnName, ',')
    FROM AttributeList;

    -- Build the dynamic pivot query
    SET @SQL = N'
    WITH RecentPersonnel AS (
        SELECT DISTINCT p.PersonnelID 
        FROM Personnel p
        JOIN AttributeValues av ON p.PersonnelID = av.PersonnelID
        WHERE av.LastUpdated >= DATEADD(month, -' + CAST(@MonthsBack AS NVARCHAR(10)) + ', GETDATE())
    ), 
    BaseData AS (
            -- Get all attributes and their values
        SELECT 
            p.PersonnelID,
            p.FirstName,
            p.LastName,
            a.AttributeName,
            av.AttributeValue,
            av.LastUpdated
        FROM RecentPersonnel rp
        JOIN Personnel p ON rp.PersonnelID = p.PersonnelID
        LEFT JOIN AttributeValues av ON p.PersonnelID = av.PersonnelID
        LEFT JOIN Attributes a ON av.AttributeID = a.AttributeID
        WHERE av.AttributeValue IS NOT NULL
        ' + CASE WHEN @WhereClause <> '' THEN 'AND p.PersonnelID IN (
            SELECT PersonnelID 
            FROM Personnel p
            ' + @WhereClause + '
        )' ELSE '' END + '
    )

    SELECT 
        PersonnelID,
        FirstName,
        LastName,' + @Columns + '
    FROM BaseData
    PIVOT (
            MAX(AttributeValue)
            FOR AttributeName IN (' + @Columns + ')
        ) AS PivotTable'

    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL;

    -- Clean up
    DROP TABLE #Conditions;
END;