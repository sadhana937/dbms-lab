CREATE DATABASE Sailors;
USE Sailors;

CREATE TABLE SAILORS (
    sid INT PRIMARY KEY,
    sname VARCHAR(50),
    rating FLOAT4,
    age INT
);

CREATE TABLE BOAT (
    bid INT PRIMARY KEY,
    bname VARCHAR(50),
    color VARCHAR(50)
);

CREATE TABLE RSERVERS (
    sid INT,
    bid INT,
    sdate DATE,
    PRIMARY KEY (sid, bid),
    FOREIGN KEY (sid) REFERENCES SAILORS (sid),
    FOREIGN KEY (bid) REFERENCES BOAT (bid)
);

INSERT INTO SAILORS (sid, sname, rating, age) VALUES
    (101, 'Albert', 8.7, 34),
    (102, 'John', 9.6, 28),
    (103, 'Evara', 7.8, 21),
    (104, 'Sana', 8.4, 24),
    (105, 'Luna', 9.1, 26),
    (106, 'H Storm', 4.5, 44),
    (107, 'A Storm', 4.7, 43);

INSERT INTO BOAT (bid, bname, color) VALUES
    (201, 'Boat1', 'Red'),
    (202, 'Boat2', 'Blue'),
    (203, 'Boat3', 'Green'),
    (204, 'Boat4', 'Yellow'),
    (205, 'Boat5', 'White');

INSERT INTO RSERVERS (sid, bid, sdate) VALUES
    (101, 201, '2023-01-15'),
    (102, 202, '2023-01-16'),
    (103, 203, '2023-01-17'),
    (104, 204, '2023-01-18'),
    (105, 205, '2023-01-19');

SELECT * FROM SAILORS;

SELECT * FROM BOAT;

SELECT * FROM RSERVERS;

-- Find the color of boat reserved by Albert
SELECT color
FROM BOAT
WHERE bid = (SELECT bid FROM RSERVERS WHERE sid = (SELECT sid FROM SAILORS WHERE sname = 'Albert'));

SELECT b.color
FROM SAILORS s
JOIN RSERVERS r ON s.sid = r.sid
JOIN BOAT b ON b.bid = r.bid
WHERE s.sname = 'Albert';

-- Find all sailor id’s of sailors who have a rating of at least 8 or reserved boat 103
SELECT s.sid
FROM SAILORS s
JOIN RSERVERS r ON s.sid = r.sid
WHERE s.rating >= 8.0 OR r.bid = 203;

-- Find the names of sailors who have not reserved a boat whose name contains the string “storm”. Order the names in ascending order
INSERT INTO BOAT (bid, bname, color) VALUES
    (206, 'H Storm', 'Teal'),
    (207, 'A Storm', 'Burgundy');
UPDATE RSERVERS SET bid = 207 WHERE sid = 103;

SELECT sname
FROM SAILORS
WHERE sid NOT IN (SELECT r.sid FROM RSERVERS r JOIN BOAT b ON r.bid = b.bid WHERE b.bname LIKE '%Storm')
ORDER BY sname;

-- Find the names of sailors who have reserved all boats
SELECT s.sname
FROM SAILORS s
JOIN RSERVERS r ON s.sid = r.sid
GROUP BY s.sname, s.sid
HAVING COUNT(DISTINCT r.bid) = (SELECT COUNT(*) FROM BOAT);

-- Find the name and age of the oldest sailor
SELECT sname, age
FROM SAILORS
WHERE age = (SELECT MAX(age) FROM SAILORS);

-- For each boat which was reserved by at least 5 sailors with age >= 40, find the boat id and the average age of such sailors.
INSERT INTO SAILORS (sid, sname, rating, age) VALUES
    (106, 'David', 8.5, 45),
    (107, 'Emma', 7.9, 41),
    (108, 'Frank', 8.2, 42),
    (109, 'Grace', 9.0, 40),
    (110, 'Henry', 7.6, 48),
    (111, 'Ivy', 8.7, 44),
    (112, 'Jack', 8.9, 43),
    (113, 'Karen', 7.8, 47),
    (114, 'Leo', 9.2, 40),
    (115, 'Mia', 8.4, 42);

INSERT INTO RSERVERS (sid, bid, sdate) VALUES
    (106, 201, '2023-01-20'),
    (107, 202, '2023-01-21'),
    (108, 203, '2023-01-22'),
    (109, 204, '2023-01-23'),
    (110, 205, '2023-01-24'),
    (111, 201, '2023-01-25'),
    (112, 202, '2023-01-26'),
    (113, 203, '2023-01-27'),
    (114, 204, '2023-01-28'),
    (115, 205, '2023-01-29');

SELECT rs.bid AS boat_id, AVG(s.age) AS avg_age
FROM SAILORS s
JOIN RSERVERS rs ON s.sid = rs.sid
WHERE s.age >= 40
GROUP BY rs.bid
HAVING COUNT(DISTINCT rs.sid) >= 5;

-- Create a view that shows the names and colours of all the boats that have been reserved by a sailor with a specific rating.
CREATE OR REPLACE VIEW ReservedBoatsByRating AS
SELECT DISTINCT b.bname AS boat_name, b.color AS boat_color
FROM BOAT b
JOIN RSERVERS r ON b.bid = r.bid
JOIN SAILORS s ON r.sid = s.sid
WHERE s.rating = 9.0;

SELECT * FROM ReservedBoatsByRating;

-- A trigger that prevents boats from being deleted If they have active reservations.
DELIMITER //

CREATE TRIGGER PreventBoatDeletion
BEFORE DELETE ON BOAT
FOR EACH ROW
BEGIN
    DECLARE reservation_count INT;

    -- Check if the boat has active reservations
    SELECT COUNT(*)
    INTO reservation_count
    FROM RSERVERS
    WHERE bid = OLD.bid;

    -- If the boat has active reservations, prevent deletion
    IF reservation_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete boat with active reservations';
    END IF;
END;
//

DELIMITER ;

DELETE FROM BOAT WHERE bid=201;
-- Error Code: 1644. Cannot delete boat with active reservations
