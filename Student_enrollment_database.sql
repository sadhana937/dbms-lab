CREATE DATABASE IF NOT EXISTS Student_enrollment4;
USE Student_enrollment4;

CREATE TABLE IF NOT EXISTS STUDENT (
    regno VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    major VARCHAR(100),
    bdate DATE
);

CREATE TABLE IF NOT EXISTS COURSE (
    course INT PRIMARY KEY,
    cname VARCHAR(100),
    dept VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS ENROLL (
    regno VARCHAR(10),
    course INT,
    sem INT,
    marks INT,
    FOREIGN KEY (regno) REFERENCES STUDENT(regno),
    FOREIGN KEY (course) REFERENCES COURSE(course)
);

CREATE TABLE IF NOT EXISTS TEXT (
    book_ISBN INT PRIMARY KEY,
    book_title VARCHAR(100),
    publisher VARCHAR(100),
    author VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS BOOK_ADOPTION (
    course INT,
    sem INT,
    book_ISBN INT,
    FOREIGN KEY (course) REFERENCES COURSE(course),
    FOREIGN KEY (book_ISBN) REFERENCES TEXT(book_ISBN)
);

INSERT INTO STUDENT (regno, name, major, bdate) VALUES
('S1', 'Alice', 'Computer Science', '2000-01-01'),
('S2', 'Bob', 'Mechanical Engineering', '2001-02-02'),
('S3', 'Charlie', 'Electrical Engineering', '1999-03-03'),
('S4', 'David', 'Computer Science', '2002-04-04'),
('S5', 'Eve', 'Civil Engineering', '2003-05-05');

INSERT INTO COURSE (course, cname, dept) VALUES
(101, 'Introduction to CS', 'CS'),
(102, 'Database Management Systems', 'CS'),
(103, 'Linear Algebra', 'Math'),
(104, 'Mechanics', 'Mech'),
(105, 'Circuit Theory', 'EE');

INSERT INTO ENROLL (regno, course, sem, marks) VALUES
('S1', 101, 1, 85),
('S2', 101, 1, 78),
('S3', 101, 1, 92),
('S4', 102, 1, 88),
('S5', 102, 1, 79);

INSERT INTO TEXT (book_ISBN, book_title, publisher, author) VALUES
(1001, 'Database Systems: The Complete Book', 'Pearson', 'Hector Garcia-Molina, Jeffrey D. Ullman, Jennifer Widom'),
(1002, 'Database System Concepts', 'McGraw-Hill', 'Abraham Silberschatz, Henry F. Korth, S. Sudarshan'),
(1003, 'Introduction to Algorithms', 'MIT Press', 'Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, Clifford Stein'),
(1004, 'Linear Algebra and Its Applications', 'Pearson', 'David C. Lay, Steven R. Lay, Judi J. McDonald'),
(1005, 'Engineering Mechanics: Dynamics', 'Wiley', 'J. L. Meriam, L. G. Kraige');

INSERT INTO BOOK_ADOPTION (course, sem, book_ISBN) VALUES
(102, 1, 1001),
(103, 2, 1004);

INSERT INTO BOOK_ADOPTION (course, sem, book_ISBN) VALUES
(101, 2, 1001);

INSERT INTO BOOK_ADOPTION (course, sem, book_ISBN) VALUES
(101, 2, 1002);

INSERT INTO BOOK_ADOPTION (course, sem, book_ISBN) VALUES
(101, 2, 1003);

-- Demonstrate how you add a new text book to the database and make this book be adopted by some department
INSERT INTO TEXT (book_ISBN, book_title, publisher, author) VALUES
(1006, 'New Book', 'New Publisher', 'New Author');

INSERT INTO BOOK_ADOPTION (course, sem, book_ISBN) VALUES
(101, 1, 1006);

-- Produce a list of text books (include Course #, Book-ISBN, Book-title) in the alphabetical order for courses offered by the ‘CS’ department that use more than two books.
SELECT course, book_ISBN, book_title
FROM BOOK_ADOPTION 
JOIN COURSE USING(course) 
JOIN TEXT USING(book_ISBN) 
WHERE dept="CS" 
AND course IN (
    SELECT course
    FROM BOOK_ADOPTION 
    GROUP BY course
    HAVING COUNT(*) > 2
)
ORDER BY book_title;

-- List any department that has all its adopted books published by a specific publisher
SELECT DISTINCT dept FROM
COURSE WHERE dept IN(
	SELECT dept FROM COURSE JOIN BOOK_ADOPTION 
    USING(course) JOIN TEXT USING(book_ISBN) 
    WHERE publisher='Pearson'
)
AND 
dept NOT IN(
	SELECT dept FROM COURSE JOIN BOOK_ADOPTION 
    USING(course) JOIN TEXT USING(book_ISBN) 
    WHERE publisher != 'Pearson'
);


-- List the students who have scored maximum marks in ‘DBMS’ course
SELECT E.regno, S.name, E.marks
FROM ENROLL E
JOIN STUDENT S ON E.regno = S.regno
WHERE E.course = 102
AND E.marks = (
    SELECT MAX(marks)
    FROM ENROLL
    WHERE course = 102
);

-- Create a view to display all the courses opted by a student along with marks obtained
CREATE OR REPLACE VIEW StudentCourseMarks AS
SELECT S.name, C.cname, E.marks
FROM ENROLL E
JOIN STUDENT S ON E.regno = S.regno
JOIN COURSE C ON E.course = C.course;

SELECT * FROM StudentCourseMarks;

-- Create a trigger that prevents a student from enrolling in a course if the marks prerequisite is less than 40
DELIMITER //

CREATE TRIGGER EnrollCheck
BEFORE INSERT ON ENROLL
FOR EACH ROW
BEGIN
    IF NEW.marks < 40 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Marks prerequisite not met for enrollment';
    END IF;
END;
//

DELIMITER ;

-- Attempt to insert a new enrollment record with marks below the prerequisite
INSERT INTO ENROLL (regno, course, sem, marks) VALUES ('S3', 101, 1, 35);
