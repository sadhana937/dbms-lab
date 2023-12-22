CREATE DATABASE Company2;
USE Company2;

-- Create EMPLOYEE table
CREATE TABLE EMPLOYEE (
    SSN VARCHAR(11) PRIMARY KEY,
    Name VARCHAR(100),
    Address VARCHAR(100),
    Sex CHAR(1),
    Salary DECIMAL(10, 2),
    SuperSSN VARCHAR(11),
    DNo INT
);

-- Create DEPARTMENT table
CREATE TABLE DEPARTMENT (
    DNo INT PRIMARY KEY,
    DName VARCHAR(100),
    MgrSSN VARCHAR(11),
    MgrStartDate DATE,
    FOREIGN KEY (MgrSSN) REFERENCES EMPLOYEE(SSN)
);

ALTER TABLE EMPLOYEE ADD FOREIGN KEY (DNo) REFERENCES DEPARTMENT(DNo);

-- Create DLOCATION table
CREATE TABLE DLOCATION (
    DNo INT PRIMARY KEY,
    DLoc VARCHAR(100)
);

-- Create PROJECT table
CREATE TABLE PROJECT (
    PNo INT PRIMARY KEY,
    PName VARCHAR(100),
    PLocation VARCHAR(100),
    DNo INT,
    FOREIGN KEY (DNo) REFERENCES DEPARTMENT(DNo)
);

-- Create WORKS_ON table
CREATE TABLE WORKS_ON (
    SSN VARCHAR(11),
    PNo INT,
    Hours DECIMAL(5, 2),
    PRIMARY KEY (SSN, PNo),
    FOREIGN KEY (SSN) REFERENCES EMPLOYEE(SSN),
    FOREIGN KEY (PNo) REFERENCES PROJECT(PNo)
);

-- Insert sample data into EMPLOYEE table
INSERT INTO EMPLOYEE (SSN, Name, Address, Sex, Salary, SuperSSN) VALUES
('123-45-6789', 'John Scott', '123 Main St', 'M', 60000.00, NULL),
('234-56-7890', 'Alice Johnson', '456 Oak St', 'F', 55000.00, '123-45-6789'),
('345-67-8901', 'Bob Smith', '789 Elm St', 'M', 62000.00, '123-45-6789'),
('456-78-9012', 'Jane Doe', '321 Pine St', 'F', 58000.00, '123-45-6789'),
('567-89-0123', 'James Brown', '654 Cedar St', 'M', 63000.00, '123-45-6789');

-- Insert sample data into DEPARTMENT table
INSERT INTO DEPARTMENT (DNo, DName, MgrSSN, MgrStartDate) VALUES
(1, 'HR', '123-45-6789', '2022-01-01'),
(2, 'Finance', '234-56-7890', '2022-01-01'),
(3, 'IT', '345-67-8901', '2022-01-01');

UPDATE EMPLOYEE SET Dno = 1 WHERE SSN = '123-45-6789';
UPDATE EMPLOYEE SET Dno = 2 WHERE SSN = '234-56-7890';
UPDATE EMPLOYEE SET Dno = 1 WHERE SSN = '345-67-8901';
UPDATE EMPLOYEE SET Dno = 2 WHERE SSN = '456-78-9012';
UPDATE EMPLOYEE SET Dno = 3 WHERE SSN = '567-89-0123';

-- Insert sample data into DLOCATION table
INSERT INTO DLOCATION (DNo, DLoc) VALUES
(1, 'New York'),
(2, 'Los Angeles'),
(3, 'San Francisco');

-- Insert sample data into PROJECT table
INSERT INTO PROJECT (PNo, PName, PLocation, DNo) VALUES
(1, 'Project A', 'New York', 1),
(2, 'Project B', 'Los Angeles', 2),
(3, 'Project C', 'San Francisco', 3);

-- Insert sample data into WORKS_ON table
INSERT INTO WORKS_ON (SSN, PNo, Hours) VALUES
('123-45-6789', 1, 40),
('234-56-7890', 2, 35),
('345-67-8901', 3, 42),
('456-78-9012', 1, 38),
('567-89-0123', 2, 40);

-- Make a list of all project numbers for projects that involve an employee whose last name is ‘Scott’, either as a worker or as a manager of the department that controls the project.
SELECT DISTINCT P.PNo,E.Name
FROM PROJECT P
JOIN WORKS_ON W ON P.PNo = W.PNo
JOIN EMPLOYEE E ON W.SSN = E.SSN OR E.DNo = P.DNo
WHERE E.Name = 'Scott';

-- Show the resulting salaries if every employee working on the ‘IoT’ project is given a 10 percent raise
INSERT INTO PROJECT (PNo, PName, PLocation, DNo) VALUES
(5, 'IoT', 'New York', 2);
INSERT INTO WORKS_ON VALUES ('234-56-7890', 5, 56);
UPDATE EMPLOYEE
SET Salary = Salary * 1.10
WHERE SSN IN (
    SELECT SSN
    FROM WORKS_ON
    WHERE PNo = (
        SELECT PNo
        FROM PROJECT
        WHERE PName = 'IoT'
    )
);
select * from EMPLOYEE;

-- Find the sum of the salaries of all employees of the ‘Accounts’ department, as well as the maximum salary, the minimum salary, and the average salary in this department
INSERT INTO DEPARTMENT (DNo, DName, MgrSSN, MgrStartDate) VALUES
(4, 'Accounts', '123-45-6789', '2022-01-01');
UPDATE EMPLOYEE SET DNo=4 WHERE SSN='345-67-8901';
UPDATE EMPLOYEE SET DNo=4 WHERE SSN='456-78-9012';

SELECT 
    SUM(E.Salary) AS TotalSalaries,
    MAX(E.Salary) AS MaxSalary,
    MIN(E.Salary) AS MinSalary,
    AVG(E.Salary) AS AvgSalary
FROM 
    EMPLOYEE E
    JOIN DEPARTMENT D ON E.DNo = D.DNo
WHERE 
    D.DName = 'Accounts';

-- Retrieve the name of each employee who works on all the projects controlled by department number 5 (use NOT EXISTS operator).
SELECT DISTINCT E.Name
FROM EMPLOYEE E
JOIN WORKS_ON W ON E.SSN = W.SSN
JOIN PROJECT P ON W.PNo = P.PNo
WHERE P.DNo = 5
AND NOT EXISTS (
    SELECT *
    FROM PROJECT P2
    WHERE P2.DNo = 5
    AND P2.PNo NOT IN (
        SELECT W2.PNo
        FROM WORKS_ON W2
        WHERE W2.SSN = E.SSN
    )
);

-- For each department that has more than five employees, retrieve the department number and the number of its employees who are making more than Rs. 6,00,000.
SELECT D.DNo AS DepartmentNumber, COUNT(*) AS NumEmployeesAboveThreshold
FROM EMPLOYEE E
JOIN DEPARTMENT D ON E.DNo = D.DNo
WHERE E.Salary > 600000
GROUP BY D.DNo
HAVING COUNT(*) > 5;

-- Create a view that shows name, dept name and location of all employees
CREATE VIEW EmployeeDetails AS
SELECT E.Name AS EmployeeName, D.DName AS DepartmentName, DL.DLoc AS DepartmentLocation
FROM EMPLOYEE E
JOIN DEPARTMENT D ON E.DNo = D.DNo
JOIN DLOCATION DL ON E.DNo = DL.DNo;

SELECT * FROM EmployeeDetails;

-- Create a trigger that prevents a project from being deleted if it is currently being worked by any employee
DELIMITER //

CREATE TRIGGER PreventProjectDeletion
BEFORE DELETE ON PROJECT
FOR EACH ROW
BEGIN
    DECLARE project_count INT;

    -- Check if the project is being worked on by any employee
    SELECT COUNT(*)
    INTO project_count
    FROM WORKS_ON
    WHERE PNo = OLD.PNo;

    -- If the project is being worked on, prevent deletion
    IF project_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project cannot be deleted as it is being worked on by one or more employees';
    END IF;
END;
//
DELIMITER ;

DELETE FROM PROJECT WHERE PNo = 2;
-- Error Code: 1644. Project cannot be deleted as it is being worked on by one or more employees
