-- Stored Procedure: Add New Attribute to Attributes Table
CREATE PROCEDURE sp_AddNewAttribute
    @AttributeName NVARCHAR(50),
    @DataType NVARCHAR(20),
    @IsFormula BIT = 0,
    @Formula NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            -- Add New Attribute
            INSERT INTO Attributes (AttributeName, DataType, IsFormula)
            VALUES (@AttributeName, @DataType, @IsFormula);
            
            DECLARE @NewAttributeID INT = SCOPE_IDENTITY();
            
            -- Add New Formula (if exists) in Formula Table 
            IF @IsFormula = 1 AND @Formula IS NOT NULL
            BEGIN
                INSERT INTO Formulas (AttributeID, FormulaExpression)
                VALUES (@NewAttributeID, @Formula);
            END
            
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW;
    END CATCH
END;

-- Stored Procedure: Update Attribute Value
CREATE PROCEDURE sp_UpdateAttributeValue
    @PersonnelID INT,
    @AttributeName NVARCHAR(50),
    @Value NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        DECLARE @AttributeID INT;
        
        SELECT @AttributeID = AttributeID 
        FROM Attributes 
        WHERE AttributeName = @AttributeName;
        
        IF EXISTS (SELECT 1 FROM AttributeValues 
                  WHERE PersonnelID = @PersonnelID 
                  AND AttributeID = @AttributeID)
        BEGIN
            UPDATE AttributeValues
            SET AttributeValue = @Value,
                LastUpdated = GETDATE()
            WHERE PersonnelID = @PersonnelID 
            AND AttributeID = @AttributeID;
        END
        ELSE
        BEGIN
            INSERT INTO AttributeValues (PersonnelID, AttributeID, AttributeValue)
            VALUES (@PersonnelID, @AttributeID, @Value);
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

-- Stored Procedure: Insert, Update, Delete row to Personnel Main Table
CREATE PROCEDURE sp_ManagePersonnel
    @Action NVARCHAR(10), -- Could be 'ADD', 'EDIT', or 'DELETE'
    @PersonnelID INT,
    @FirstName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Condition NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        IF @Action = 'ADD'
        BEGIN
            INSERT INTO Personnel (PersonnelID, FirstName, LastName)
            VALUES (@PersonnelID, @FirstName, @LastName);
        END
        ELSE IF @Action = 'EDIT'
        BEGIN
            UPDATE Personnel
            SET FirstName = ISNULL(@FirstName, FirstName),
                LastName = ISNULL(@LastName, LastName)
            WHERE PersonnelID = @PersonnelID;
        END
        ELSE IF @Action = 'DELETE'
        BEGIN
            -- Using a Dynamic SQL to apply Delete Condition
            DECLARE @SQL NVARCHAR(MAX);
            SET @SQL = 'DELETE FROM Personnel WHERE PersonnelID = @PersonnelID';
            
            IF @Condition IS NOT NULL
                SET @SQL = @SQL + ' AND ' + @Condition;
                
            EXEC sp_executesql @SQL, 
                N'@PersonnelID INT', 
                @PersonnelID;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;

-- Stored Procedure: Calculate and Update Furmula Values
CREATE PROCEDURE sp_CalculateFormulaValues
    @PersonnelID INT = NULL -- Null means Calculate for all personnel
AS
BEGIN
    BEGIN TRY

        DECLARE @AttributeID INT;
        DECLARE @Formula NVARCHAR(MAX);
        
        IF @PersonnelID IS NOT NULL:
            DECLARE personnel_cursor CURSOR FOR
            SELECT PersonnelID
            FROM Personnel
            WHERE PersonnelID = @PersonnelID;   -- Create a cursor with just one record
        ELSE: 
            DECLARE personnel_cursor CURSOR FOR
            SELECT PersonnelID
            FROM Personnel;     -- Create a cursor for all personnel

        DECLARE formula_cursor CURSOR FOR
        SELECT a.AttributeID, f.FormulaExpression
        FROM Attributes a
        JOIN Formulas f ON a.AttributeID = f.AttributeID
        WHERE a.IsFormula = 1;

        OPEN personnel_cursor;
        FETCH NEXT FROM personnel_cursor INTO @PersonnelID;      

        OPEN formula_cursor;

        WHILE @@FETCH_STATUS = 0    -- It may loops once regarding @PersonnelID parameter
        BEGIN

            FETCH ABSOLUTE 0 FROM formula_cursor;
            FETCH NEXT FROM formula_cursor INTO @AttributeID, @Formula;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Create and Run a Dynamic SQL for Calculating Formula
                DECLARE @CalcSQL NVARCHAR(MAX);
                SET @CalcSQL = 'UPDATE AttributeValues
                            SET AttributeValue = CONVERT(NVARCHAR(MAX), ' + @Formula + '),
                                LastUpdated = GETDATE()
                            WHERE AttributeID = @AttributeID AND PersonnelID = @PersonnelID';

                EXEC sp_executesql @CalcSQL, 
                    N'@AttributeID INT, @PersonnelID INT', 
                    @AttributeID, @PersonnelID;
                    
                FETCH NEXT FROM formula_cursor INTO @AttributeID, @Formula;
            END

            FETCH NEXT FROM personnel_cursor INTO @PersonnelID;
        END
        
        CLOSE formula_cursor;
        DEALLOCATE formula_cursor;

        CLOSE personnel_cursor;
        DEALLOCATE personnel_cursor;

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('global', 'formula_cursor') >= 0
        BEGIN
            CLOSE formula_cursor;
            DEALLOCATE formula_cursor;
        END
        
        IF CURSOR_STATUS('global', 'personnel_cursor') >= 0
        BEGIN
            CLOSE personnel_cursor;
            DEALLOCATE personnel_cursor;
        END

        THROW;
    END CATCH
END;



