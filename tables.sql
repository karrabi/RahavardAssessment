-- Main Table
CREATE TABLE Personnel (
    PersonnelID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

-- Attributes Table
CREATE TABLE Attributes (
    AttributeID INT IDENTITY(1,1) PRIMARY KEY,
    AttributeName NVARCHAR(50),
    DataType NVARCHAR(20), -- VARCHAR, INT, DATE, etc.
    IsFormula BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Attributes' Values Table
CREATE TABLE AttributeValues (
    PersonnelID INT,
    AttributeID INT,
    AttributeValue NVARCHAR(MAX),
    LastUpdated DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (PersonnelID, AttributeID),
    FOREIGN KEY (PersonnelID) REFERENCES Personnel(PersonnelID),
    FOREIGN KEY (AttributeID) REFERENCES Attributes(AttributeID)
);

-- Formulas Table
CREATE TABLE Formulas (
    AttributeID INT PRIMARY KEY,
    FormulaExpression NVARCHAR(MAX),
    FOREIGN KEY (AttributeID) REFERENCES Attributes(AttributeID)
);