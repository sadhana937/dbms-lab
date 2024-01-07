create database Sailors1;
use Sailors1;

CREATE TABLE SAILORS (
    sid INT NOT NULL PRIMARY KEY,
    sname VARCHAR(50),
    rating FLOAT4,
    age INT
);
    
CREATE TABLE BOAT (
    bid INT NOT NULL PRIMARY KEY,
    bname VARCHAR(50),
    color VARCHAR(50)
);

CREATE TABLE RSERVERS (
    sid INT,
    bid INT,
    sdate DATE,
    FOREIGN KEY (sid)
        REFERENCES SAILORS (sid) ON DELETE CASCADE,
    FOREIGN KEY (bid)
        REFERENCES BOAT (bid) ON DELETE CASCADE
);
    
insert into SAILORS(sid, sname, rating, age) values
(101, 'Albert', 8.7, 34),
(102, 'John', 9.6, 28),
(103, 'Evara', 7.8, 21),
(104, 'Sana', 8.4, 24),
(105, 'Luna', 9.1, 26);

SELECT 
    *
FROM
    SAILORS;

insert into BOAT(bid, bname, color) values
(201, 'Boat1', 'Red'),
(202, 'Boat2', 'Blue'),
(203, 'Boat3', 'Green'),
(204, 'Boat4', 'Yellow'),
(205, 'Boat5', 'White');

SELECT 
    *
FROM
    BOAT;

insert into RSERVERS(sid, bid, sdate) values
(101, 201, '2023-01-01'),
(101, 202, '2023-02-01'),
(101, 203, '2023-03-01'),
(101, 204, '2023-04-01'),
(101, 205, '2023-05-01'),
(101, 201, '2023-01-01'),
(102, 201, '2023-02-01'),
(103, 201, '2023-03-01'),
(104, 201, '2023-04-01'),
(105, 201, '2023-05-01'),
(102, 202, '2023-02-01'),
(103, 203, '2023-03-01'),
(104, 204, '2023-04-01'),
(105, 205, '2023-05-01');

SELECT 
    *
FROM
    RSERVERS;

-- Find the color of boat reserved by albert
SELECT b.color FROM BOAT b JOIN RSERVERS r ON b.bid = r.bid JOIN SAILORS s ON s.sid = r.sid WHERE s.sname LIKE "%Albert%";

-- Find all sailor id’s of sailors who have a rating of at least 8 or reserved boat 103
SELECT s.sid FROM RSERVERS r LEFT JOIN SAILORS s ON s.sid = r.sid WHERE s.rating >= 8.0 OR r.bid = 203;

-- Find the names of sailors who have not reserved a boat whose name contains the string “storm”. Order the names in ascending order
SELECT DISTINCT sname FROM SAILORS WHERE sid NOT IN ( SELECT r.sid FROM RSERVERS r JOIN BOAT b ON b.bid = r.bid WHERE b.bname LIKE "%Storm") ORDER BY sname;

-- Find the names of sailors who have reserved all boats
SELECT s.sname FROM SAILORS s JOIN RSERVERS r ON r.sid = s.sid GROUP BY s.sname, s.sid HAVING COUNT(DISTINCT r.bid) = (SELECT COUNT(*) FROM BOAT);

-- Find the name and age of the oldest sailor
SELECT sname, age FROM SAILORS WHERE age = (SELECT MAX(age) FROM SAILORS);

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
(107, 201, '2023-01-21'),
(108, 201, '2023-01-22'),
(109, 201, '2023-01-23'),
(110, 201, '2023-01-24'),
(111, 202, '2023-01-25'),
(112, 202, '2023-01-26'),
(113, 202, '2023-01-27'),
(114, 202, '2023-01-28'),
(115, 202, '2023-01-29');

SELECT r.bid as boat_id, AVG(s.age) as avg_age FROM SAILORS s JOIN RSERVERS r ON s.sid = r.sid WHERE s.age >= 40 GROUP BY r.bid HAVING COUNT(DISTINCT r.sid) >= 5;

-- Create a view that shows the names and colours of all the boats that have been reserved by a sailor with a specific rating.
-- (not working!!!) 
CREATE OR REPLACE VIEW ReservedBoatsByRating AS
SELECT DISTINCT s.sname AS sailor_name, b.bname AS boat_name, b.color
FROM SAILORS s
JOIN RSERVERS r ON s.sid = r.sid
JOIN BOAT b ON r.bid = b.bid
WHERE s.rating = 8.7;

CREATE OR REPLACE VIEW ReservedBoatsByRating AS
SELECT DISTINCT s.sname AS sailor_name, b.bname AS boat_name, b.color 
FROM SAILORS s, RSERVERS r, BOAT b WHERE s.sid = r.sid AND b.bid = r.bid AND s.rating = 7.9;
-- check 
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
