USE DataCoreRRHH;
GO

CREATE TABLE rrhh.Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL,
    Description VARCHAR(255) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE rrhh.Positions (
    PositionID INT IDENTITY(1,1) PRIMARY KEY,
    PositionName VARCHAR(100) NOT NULL,
    DepartmentID INT NOT NULL,
    BaseSalary DECIMAL(12,2) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Positions_Departments
        FOREIGN KEY (DepartmentID)
        REFERENCES rrhh.Departments(DepartmentID)
);
GO

CREATE TABLE rrhh.Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FileNumber VARCHAR(20) NOT NULL,
    FirstName VARCHAR(80) NOT NULL,
    LastName VARCHAR(80) NOT NULL,
    DNI VARCHAR(20) NOT NULL,
    Email VARCHAR(120) NULL,
    Phone VARCHAR(30) NULL,
    HireDate DATE NOT NULL,
    PositionID INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_Employees_FileNumber UNIQUE (FileNumber),
    CONSTRAINT UQ_Employees_DNI UNIQUE (DNI),

    CONSTRAINT FK_Employees_Positions
        FOREIGN KEY (PositionID)
        REFERENCES rrhh.Positions(PositionID)
);
GO

CREATE TABLE rrhh.EmergencyContacts (
    ContactID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    FullName VARCHAR(120) NOT NULL,
    Relationship VARCHAR(50) NOT NULL,
    Phone VARCHAR(30) NOT NULL,

    CONSTRAINT FK_EmergencyContacts_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES rrhh.Employees(EmployeeID)
);
GO