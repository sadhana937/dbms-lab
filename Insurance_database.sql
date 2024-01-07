CREATE DATABASE Insurance2;
USE Insurance2;

CREATE TABLE PERSON (
    driver_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50),
    address VARCHAR(50)
);

CREATE TABLE CAR (
    regno VARCHAR(10) PRIMARY KEY,
    model VARCHAR(50),
    year INT
);

CREATE TABLE ACCIDENT (
    report_number INT PRIMARY KEY,
    acc_date DATE,
    location VARCHAR(50)
);

CREATE TABLE OWNS (
    driver_id VARCHAR(10),
    regno VARCHAR(10),
    FOREIGN KEY (driver_id) REFERENCES PERSON(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (regno) REFERENCES CAR(regno) ON DELETE CASCADE
);

CREATE TABLE PARTICIPATED (
    driver_id VARCHAR(10),
    regno VARCHAR(10),
    report_number INT,
    damage_amount INT,
    FOREIGN KEY (driver_id) REFERENCES PERSON(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (regno) REFERENCES CAR(regno) ON DELETE CASCADE,
    FOREIGN KEY (report_number) REFERENCES ACCIDENT(report_number) ON DELETE CASCADE
);

INSERT INTO PERSON (driver_id, name, address) VALUES
    ('D001', 'John Smith', '123 Main Street'),
    ('D002', 'Alice Johnson', '456 Elm Street'),
    ('D003', 'Bob Brown', '789 Oak Street'),
    ('D004', 'Emma Davis', '101 Pine Street'),
    ('D005', 'Michael Wilson', '202 Maple Street'),
	('D006', 'Jane Smith', '123 Main Street'),
    ('D007', 'John Doe', '123 Main Street');
    
INSERT INTO CAR (regno, model, year) VALUES
    ('ABC123', 'Toyota', 2019),
    ('DEF456', 'Honda', 2020),
    ('GHI789', 'Ford', 2018),
    ('JKL012', 'Chevrolet', 2021),
    ('MNO345', 'Tesla', 2022),
	('PQR123', 'Mazda', 2019),
	('PQR456', 'Mazda', 2019);

INSERT INTO ACCIDENT (report_number, acc_date, location) VALUES
    (1001, '2021-05-10', 'Intersection of 1st St and Main St'),
    (1002, '2021-07-15', 'Highway 101'),
    (1003, '2021-09-20', 'Parking lot of ABC Mall'),
    (1004, '2021-11-05', 'Residential area on Elm St'),
    (1005, '2021-12-30', 'Downtown Square');

INSERT INTO OWNS (driver_id, regno) VALUES
    ('D001', 'ABC123'),
    ('D002', 'DEF456'),
    ('D003', 'GHI789'),
    ('D004', 'JKL012'),
    ('D005', 'MNO345'),
	('D001', 'PQR123'),
	('D001', 'PQR456');
INSERT INTO PARTICIPATED (driver_id, regno, report_number, damage_amount) VALUES
    ('D001', 'ABC123', 1001, 5000),
    ('D002', 'DEF456', 1002, 3000),
    ('D003', 'GHI789', 1003, 2000),
    ('D004', 'JKL012', 1004, 4000),
    ('D005', 'MNO345', 1005, 6000);

SELECT * FROM PERSON;

SELECT * FROM CAR;

SELECT * FROM ACCIDENT;

SELECT * FROM OWNS;

SELECT * FROM PARTICIPATED;

-- Find the total number of people who owned cars that were involved in accidents in 2021
SELECT COUNT(DISTINCT p.driver_id) AS total_people_involved
FROM PERSON p
JOIN OWNS o ON p.driver_id = o.driver_id
JOIN PARTICIPATED pt ON o.regno = pt.regno
JOIN ACCIDENT a ON pt.report_number = a.report_number
WHERE YEAR(a.acc_date) = 2021;

-- Find the number of accidents in which the cars belonging to “Smith” were involved
SELECT COUNT(*)
FROM PARTICIPATED pt
JOIN OWNS o ON pt.regno = o.regno
JOIN PERSON p ON o.driver_id = p.driver_id
WHERE p.name LIKE '%Smith%';

-- Add a new accident to the database; assume any values for required attributes.
INSERT INTO ACCIDENT(report_number, acc_date, location) VALUES
(1006, '2023-12-18', 'JSSSTU');

-- Delete the Mazda belonging to “Smith”.
DELETE FROM CAR WHERE model = 'Mazda' AND regno IN ( SELECT o.regno FROM OWNS o JOIN PERSON p USING (driver_id) WHERE p.name LIKE "%Smith%");

-- Update the damage amount for the car with license number “MNO345” in the accident with report.
UPDATE PARTICIPATED
SET damage_amount = 4999
WHERE regno = 'MNO345';

-- A view that shows models and year of cars that are involved in accident.
CREATE OR REPLACE VIEW CarsInAccidents AS
SELECT DISTINCT c.model, c.year
FROM CAR c
JOIN PARTICIPATED pt ON c.regno = pt.regno;

SELECT * FROM CarsInAccidents;

-- A trigger that prevents a driver from participating in more than 3 accidents in a given year.
DELIMITER //
CREATE TRIGGER PreventParticipation
BEFORE INSERT ON participated
FOR EACH ROW
BEGIN
	IF 2<=(SELECT COUNT(*) FROM PARTICIPATED WHERE driver_id=new.driver_id) THEN
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT='Driver in 2 accidents';
	END IF;
END;
//
DELIMITER ;
