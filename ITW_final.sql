CREATE DATABASE IF NOT EXISTS StayDine;
USE StayDine;
CREATE TABLE Users (
user_id INT PRIMARY KEY AUTO_INCREMENT,
username CHAR(75) UNIQUE NOT NULL,
email CHAR(150) UNIQUE NOT NULL,
password CHAR(100) NOT NULL,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50),
mobile_no CHAR(15) NOT NULL,
aadhaar_no VARCHAR(16) UNIQUE NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Staff_roles (
role_id INT PRIMARY KEY,
role_name VARCHAR(30) NOT NULL UNIQUE
);
CREATE TABLE Staffs (
staff_id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50),
email CHAR(100) UNIQUE NOT NULL,
mobile_no DECIMAL(10,0) NOT NULL,
manager_id INT,
role_id INT NOT NULL,
hire_date DATE NOT NULL,
CONSTRAINT fk_manager FOREIGN KEY (manager_id) REFERENCES Staffs(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_role FOREIGN KEY (role_id) REFERENCES Staff_roles(role_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE Suites (
room_number INT PRIMARY KEY,
room_type VARCHAR(50) NOT NULL,
bed_type VARCHAR(20) DEFAULT 'Double',
price_per_night DECIMAL(15,2),
max_occupants TINYINT DEFAULT 2,
is_available BOOLEAN DEFAULT TRUE,
staff_id INT,
CONSTRAINT fk_staff_hotel FOREIGN KEY (staff_id) REFERENCES Staffs(staff_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE Restaurant_diner (
table_number INT PRIMARY KEY,
capacity INT NOT NULL DEFAULT 2,
is_available BOOLEAN DEFAULT TRUE,
staff_id INT,
CONSTRAINT fk_staff_diner FOREIGN KEY (staff_id) REFERENCES Staffs(staff_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE StaffAssignments (
assignment_id INT PRIMARY KEY AUTO_INCREMENT,
staff_id INT NOT NULL,
room_number INT,
table_number INT,
assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_staff FOREIGN KEY (staff_id) REFERENCES Staffs(staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_room_st FOREIGN KEY (room_number) REFERENCES Suites(room_number) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_table_st FOREIGN KEY (table_number) REFERENCES Restaurant_diner(table_number) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE Bookings (
booking_id INT PRIMARY KEY AUTO_INCREMENT,
user_id INT NOT NULL,
room_id INT,
table_id INT,
booking_date DATE NOT NULL,
event_type VARCHAR(50),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
stat ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
CONSTRAINT fk_cust_id FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_room FOREIGN KEY (room_id) REFERENCES Suites(room_number) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_table FOREIGN KEY (table_id) REFERENCES Restaurant_diner(table_number) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE MenuItems (
menu_item_id INT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
price DECIMAL(15, 2) NOT NULL,
category VARCHAR(50) NOT NULL
);
CREATE TABLE Orders (
order_id INT PRIMARY KEY AUTO_INCREMENT,
user_id INT NOT NULL,
booking_id INT,
total_price DECIMAL(15, 2) DEFAULT 0,
order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
stat ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
CONSTRAINT fk_cust_ord_id FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_booking_id FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE OrderItems (
order_item_id INT PRIMARY KEY AUTO_INCREMENT,
order_id INT NOT NULL,
menu_item_id INT NOT NULL,
quantity INT NOT NULL DEFAULT 1,
price DECIMAL(15, 2) NOT NULL,
CONSTRAINT fk_ord_id FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_menu_id FOREIGN KEY (menu_item_id) REFERENCES MenuItems(menu_item_id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE Eventz (
event_id INT PRIMARY KEY,
event_name VARCHAR(100) NOT NULL,
price DECIMAL(15, 2) NOT NULL,
max_guests INT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE EventBookings (
booking_id INT PRIMARY KEY AUTO_INCREMENT,
user_id INT NOT NULL,
event_id INT,
event_date DATE NOT NULL,
total_price DECIMAL(10, 2) NOT NULL,
stat ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT fk_cust_ev_id FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_ev_id FOREIGN KEY (event_id) REFERENCES Eventz(event_id) ON DELETE CASCADE ON UPDATE CASCADE
);
DELIMITER //
CREATE TRIGGER ValidateEmailFormatBeforeInsertUsers
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
    IF NOT (NEW.email LIKE '%_@__%.com') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format for Users.';
    END IF;
END //
CREATE TRIGGER ValidateEmailFormatBeforeUpdateUsers
BEFORE UPDATE ON Users
FOR EACH ROW
BEGIN
    IF NOT (NEW.email LIKE '%_@__%.com') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid email format for Users.';
    END IF;
END //
CREATE TRIGGER ValidatePasswordStrengthBeforeInsertUsers
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.password) < 8 OR 
       NOT (NEW.password REGEXP '[0-9]') OR 
       NOT (NEW.password REGEXP '[A-Z]') OR 
       NOT (NEW.password REGEXP '[!@#$%^&*()]') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Password must be at least 8 characters long, contain at least one number, one uppercase letter, and one special character.';
    END IF;
END //
CREATE TRIGGER ValidatePasswordStrengthBeforeUpdateUsers
BEFORE UPDATE ON Users
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.password) < 8 OR 
       NOT (NEW.password REGEXP '[0-9]') OR 
       NOT (NEW.password REGEXP '[A-Z]') OR 
       NOT (NEW.password REGEXP '[!@#$%^&*()]') THEN
        SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'Password must be at least 8 characters long, contain at least one number, one uppercase letter, and one special character.';
    END IF;
END //
CREATE TRIGGER Assign_Housekeeper_To_Room
AFTER UPDATE ON Suites
FOR EACH ROW
BEGIN
    DECLARE housekeeper_id INT;
    IF NEW.is_available = TRUE AND NEW.staff_id IS NULL THEN
        SELECT staff_id INTO housekeeper_id
        FROM Staffs
        WHERE role_id = (SELECT role_id FROM Staff_roles WHERE role_name = 'Housekeeping')
        AND staff_id NOT IN (SELECT staff_id FROM StaffAssignments WHERE room_number = NEW.room_number)
		ORDER BY (SELECT COUNT(*) FROM StaffAssignments WHERE staff_id = Staffs.staff_id) ASC
        LIMIT 1;
        IF housekeeper_id IS NOT NULL THEN
            INSERT INTO StaffAssignments (staff_id, room_number)
            VALUES (housekeeper_id, NEW.room_number);
        END IF;
    END IF;
END //
CREATE TRIGGER Assign_Waiter_To_Table
AFTER UPDATE ON Restaurant_diner
FOR EACH ROW
BEGIN
    DECLARE waiter_id INT;
    IF NEW.is_available = TRUE AND NEW.staff_id IS NULL THEN
        SELECT staff_id INTO waiter_id
        FROM Staffs
        WHERE role_id = (SELECT role_id FROM Staff_roles WHERE role_name = 'Waiter')
        AND staff_id NOT IN (SELECT staff_id FROM StaffAssignments WHERE table_number = NEW.table_number)
        ORDER BY (SELECT COUNT(*) FROM StaffAssignments WHERE staff_id = Staffs.staff_id) ASC
        LIMIT 1;
        IF waiter_id IS NOT NULL THEN
            INSERT INTO StaffAssignments (staff_id, table_number)
            VALUES (waiter_id, NEW.table_number);
        END IF;
    END IF;
END //
CREATE TRIGGER Free_Staff_After_Payment
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.stat = 'Completed' THEN
        IF NEW.room_id IS NOT NULL THEN
            DELETE FROM StaffAssignments WHERE room_number = NEW.room_id;
        END IF;
        IF NEW.table_id IS NOT NULL THEN
            DELETE FROM StaffAssignments WHERE table_number = NEW.table_id;
        END IF;
    END IF;
END //
DELIMITER ;
CREATE VIEW FrequentCustomers AS
SELECT u.user_id, u.username, u.email, COUNT(b.booking_id) AS total_bookings
FROM Users u
JOIN Bookings b
ON u.user_id = b.user_id
GROUP BY u.user_id
HAVING COUNT(b.booking_id) > 3;
CREATE VIEW ActiveBookings AS
SELECT b.booking_id, u.username, u.email, b.room_id, b.table_id, b.booking_date, b.event_type, b.stat AS booking_status
FROM Bookings AS b
JOIN Users AS u
ON b.user_id = u.user_id
WHERE b.stat IN ('Pending', 'Confirmed');
CREATE VIEW PendingOrdersAndBookings AS
SELECT b.booking_id, u.username, b.room_id, b.table_id, b.booking_date, b.stat AS booking_status, o.order_id, o.total_price AS order_total, o.stat AS order_status
FROM Bookings AS b
LEFT JOIN Orders AS o
ON b.booking_id = o.booking_id
JOIN Users AS u
ON b.user_id = u.user_id
WHERE b.stat = 'Pending' OR o.stat = 'Pending';
CREATE VIEW StaffCurrentAssignments AS
SELECT s.staff_id, CONCAT(s.first_name, ' ', s.last_name) AS staff_name, sr.role_name, sa.room_number, sa.table_number, sa.assigned_date
FROM StaffAssignments AS sa
JOIN Staffs AS s
ON sa.staff_id = s.staff_id
JOIN Staff_roles sr
ON s.role_id = sr.role_id;
CREATE VIEW StaffWorkload AS
SELECT s.staff_id, CONCAT(s.first_name, ' ', s.last_name) AS staff_name, sr.role_name, COUNT(sa.room_number) AS total_rooms_assigned, 
COUNT(sa.table_number) AS total_tables_assigned
FROM Staffs AS s
LEFT JOIN Staff_roles AS sr
ON s.role_id = sr.role_id
LEFT JOIN StaffAssignments AS sa
ON s.staff_id = sa.staff_id
GROUP BY s.staff_id;
CREATE VIEW MenuOverview AS
SELECT category, menu_item_id AS ID, name, price
FROM MenuItems
ORDER BY category, price;
CREATE VIEW EventBookingsOverview AS
SELECT eb.booking_id, u.username, e.event_name, eb.event_date, eb.total_price, eb.stat
FROM EventBookings AS eb
JOIN Users AS u
ON eb.user_id = u.user_id
JOIN Eventz AS e
ON eb.event_id = e.event_id
WHERE eb.stat IN ('Pending', 'Confirmed');
CREATE VIEW EventParticipation AS
SELECT u.user_id, u.username, e.event_name, eb.event_date, eb.total_price
FROM EventBookings AS eb
JOIN Users AS u
ON eb.user_id = u.user_id
JOIN Eventz e ON eb.event_id = e.event_id;
INSERT INTO Staff_roles VALUES
(101, 'CEO'), (102, 'Hotel Manager'), (103, 'Restaurant Manager'), (104, 'Chef'), (105, 'Waiter'), (106, 'Housekeeper');
INSERT INTO Staffs (first_name, last_name, email, mobile_no, manager_id, role_id, hire_date) VALUES
-- CEO
('John', 'Samuel', 'john.samuel@staydine.com', 9876543210, NULL, 101, '2024-01-01'),
-- Hotel Managers
('Alice', 'Johnson', 'alice.johnson@staydine.com', 9876543211, 1, 102, '2024-01-02'),
('Bob', 'Williams', 'bob.williams@staydine.com', 9876543212, 1, 102, '2024-01-03'),
-- Restaurant Managers
('Catherine', 'Brown', 'catherine.brown@staydine.com', 9876543213, 1, 103, '2024-01-04'),
('David', 'Jones', 'david.jones@staydine.com', 9876543214, 1, 103, '2024-01-05'),
-- Chefs under Hotel Manager 1 (staff_id = 2)
('Evelyn', 'Davis', 'evelyn.davis@staydine.com', 9876543215, 2, 104, '2024-01-06'),
('Frank', 'Garcia', 'frank.garcia@staydine.com', 9876543216, 2, 104, '2024-01-07'),
('Grace', 'Martinez', 'grace.martinez@staydine.com', 9876543217, 2, 104, '2024-01-08'),
('Henry', 'Hernandez', 'henry.hernandez@staydine.com', 9876543218, 2, 104, '2024-01-09'),
('Isabella', 'Lopez', 'isabella.lopez@staydine.com', 9876543219, 2, 104, '2024-01-10'),
-- Chefs under Restaurant Manager 1 (staff_id = 4)
('James', 'Gonzalez', 'james.gonzalez@staydine.com', 9876543220, 4, 104, '2024-01-11'),
('Linda', 'Wilson', 'linda.wilson@staydine.com', 9876543221, 4, 104, '2024-01-12'),
('Michael', 'Anderson', 'michael.anderson@staydine.com', 9876543222, 4, 104, '2024-01-13'),
('Natalie', 'Thomas', 'natalie.thomas@staydine.com', 9876543223, 4, 104, '2024-01-14'),
('Oliver', 'Taylor', 'oliver.taylor@staydine.com', 9876543224, 4, 104, '2024-01-15'),
-- Waiters under Restaurant Manager 2 (staff_id = 5)
('Patricia', 'Moore', 'patricia.moore@staydine.com', 9876543225, 5, 105, '2024-01-16'),
('Quincy', 'Jackson', 'quincy.jackson@staydine.com', 9876543226, 5, 105, '2024-01-17'),
('Rachel', 'White', 'rachel.white@staydine.com', 9876543227, 5, 105, '2024-01-18'),
('Samuel', 'Harris', 'samuel.harris@staydine.com', 9876543228, 5, 105, '2024-01-19'),
('Tina', 'Martin', 'tina.martin@staydine.com', 9876543229, 5, 105, '2024-01-20'),
('Ulysses', 'Thompson', 'ulysses.thompson@staydine.com', 9876543230, 5, 105, '2024-01-21'),
('Vera', 'Garrett', 'vera.garrett@staydine.com', 9876543231, 5, 105, '2024-01-22'),
('William', 'Morris', 'william.morris@staydine.com', 9876543232, 5, 105, '2024-01-23'),
('Xena', 'Rodriguez', 'xena.rodriguez@staydine.com', 9876543233, 5, 105, '2024-01-24'),
('Yara', 'Lee', 'yara.lee@staydine.com', 9876543234, 5, 105, '2024-01-25'),
-- Housekeepers under Hotel Manager 2 (staff_id = 3)
('Zach', 'Young', 'zach.young@staydine.com', 9876543235, 3, 106, '2024-01-26'),
('Ava', 'Hall', 'ava.hall@staydine.com', 9876543236, 3, 106, '2024-01-27'),
('Ben', 'King', 'ben.king@staydine.com', 9876543237, 3, 106, '2024-01-28'),
('Chloe', 'Scott', 'chloe.scott@staydine.com', 9876543238, 3, 106, '2024-01-29'),
('Derek', 'Adams', 'derek.adams@staydine.com', 9876543239, 3, 106, '2024-01-30'),
('Ella', 'Baker', 'ella.baker@staydine.com', 9876543240, 3, 106, '2024-01-31'),
('Felix', 'Nelson', 'felix.nelson@staydine.com', 9876543241, 3, 106, '2024-02-01'),
('Grace', 'Carter', 'grace.carter@staydine.com', 9876543242, 3, 106, '2024-02-02'),
('Holly', 'Mitchell', 'holly.mitchell@staydine.com', 9876543243, 3, 106, '2024-02-03'),
('Ian', 'Perez', 'ian.perez@staydine.com', 9876543244, 3, 106, '2024-02-04'),
('Jack', 'Roberts', 'jack.roberts@staydine.com', 9876543245, 3, 106, '2024-02-05'),
('Kara', 'Turner', 'kara.turner@staydine.com', 9876543246, 3, 106, '2024-02-06'),
('Leo', 'Phillips', 'leo.phillips@staydine.com', 9876543247, 3, 106, '2024-02-07'),
('Mia', 'Campbell', 'mia.campbell@staydine.com', 9876543248, 3, 106, '2024-02-08'),
('Nina', 'Parker', 'nina.parker@staydine.com', 9876543249, 3, 106, '2024-02-09'),
('Owen', 'Evans', 'owen.evans@staydine.com', 9876543250, 3, 106, '2024-02-10'),
('Paula', 'Edwards', 'paula.edwards@staydine.com', 9876543251, 3, 106, '2024-02-11'),
('Quinn', 'Collins', 'quinn.collins@staydine.com', 9876543252, 3, 106, '2024-02-12'),
('Ray', 'Stewart', 'ray.stewart@staydine.com', 9876543253, 3, 106, '2024-02-13'),
('Sophie', 'Sanchez', 'sophie.sanchez@staydine.com', 9876543254, 3, 106, '2024-02-14'),
('Tom', 'Morris', 'tom.morris@staydine.com', 9876543255, 3, 106, '2024-02-15');
INSERT INTO Suites (room_number, room_type, bed_type, price_per_night, max_occupants, staff_id) VALUES
-- Top Floor: Penthouse
(1001, 'PentHouse', 'California King', 7000.00, 4, NULL),
(1002, 'PentHouse', 'California King', 5000.00, 2, NULL),
-- 9th Floor: VIP Lounge
(901, 'Presedential Suite', 'King', 4000.00, 6, NULL),
(902, 'Presedential Suite', 'King', 4000.00, 6, NULL),
(903, 'Presedential Suite', 'King', 4000.00, 6, NULL),
(904, 'Presedential Suite', 'King', 4000.00, 6, NULL),
(905, 'Presedential Suite', 'King', 3000.00, 4, NULL),
-- 8th Floor: VIP Lounge
(801, 'Presedential Suite', 'King', 3000.00, 4, NULL),
(802, 'Presedential Suite', 'King', 3000.00, 4, NULL),
(803, 'Presedential Suite', 'King', 3000.00, 4, NULL),
(804, 'Presedential Suite', 'King', 2500.00, 2, NULL),
(805, 'Presedential Suite', 'King', 2500.00, 2, NULL),
-- 7th Floor: Superior Rooms
(701, 'Superior Suite', 'Queen', 2300.00, 6, NULL),
(702, 'Superior Suite', 'Queen', 2300.00, 6, NULL),
(703, 'Superior Suite', 'Queen', 2300.00, 6, NULL),
(704, 'Superior Suite', 'Queen', 2300.00, 6, NULL),
(705, 'Superior Suite', 'Queen', 2300.00, 6, NULL),
(706, 'Superior Suite', 'Queen', 2100.00, 4, NULL),
(707, 'Superior Suite', 'Queen', 2100.00, 4, NULL),
-- 6th Floor: Superior Rooms
(601, 'Superior Suite', 'Queen', 2100.00, 4, NULL),
(602, 'Superior Suite', 'Queen', 2100.00, 4, NULL),
(603, 'Superior Suite', 'Queen', 2100.00, 4, NULL),
(604, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(605, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(606, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(607, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
-- 5th Floor: Superior Rooms
(501, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(502, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(503, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(504, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(505, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(506, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
(507, 'Superior Suite', 'Queen', 2000.00, 3, NULL),
-- 4th Floor: Deluxe Rooms
(401, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(402, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(403, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(404, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(405, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(406, 'Deluxe Suite', 'Double', 1900.00, 6, NULL),
(407, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(408, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(409, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(410, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
-- 3rd Floor: Deluxe Rooms
(301, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(302, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(303, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(304, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(305, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(306, 'Deluxe Suite', 'Double', 1100.00, 2, NULL),
(307, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(308, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(309, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(310, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
-- 2nd Floor: Deluxe Room
(201, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(202, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(203, 'Deluxe Suite', 'Double', 1500.00, 3, NULL),
(204, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(205, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(206, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(207, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(208, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(209, 'Deluxe Suite', 'Double', 1700.00, 4, NULL),
(210, 'Deluxe Suite', 'Double', 1700.00, 4 , NULL),
-- 1st Floor: Deluxe Rooms
(101, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(102, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(103, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(104, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(105, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(106, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(107, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(108, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(109, 'Deluxe Suite', 'Single', 1000.00, 1, NULL),
(110, 'Deluxe Suite', 'Single', 1000.00, 1, NULL);
INSERT INTO Restaurant_diner (table_number, capacity, staff_id) VALUES
-- Inserting 20 tables for 2 members
(1, 2, NULL), (2, 2, NULL), (3, 2, NULL), (4, 2, NULL), (5, 2, NULL),
(6, 2, NULL), (7, 2, NULL), (8, 2, NULL), (9, 2, NULL), (10, 2, NULL),
(11, 2, NULL), (12, 2, NULL), (13, 2, NULL), (14, 2, NULL), (15, 2, NULL),
(16, 2, NULL), (17, 2, NULL), (18, 2, NULL), (19, 2, NULL), (20, 2, NULL),
-- Inserting 15 tables for 4 members
(21, 4, NULL), (22, 4, NULL), (23, 4, NULL), (24, 4, NULL), (25, 4, NULL),
(26, 4, NULL), (27, 4, NULL), (28, 4, NULL), (29, 4, NULL), (30, 4, NULL),
(31, 4, NULL), (32, 4, NULL), (33, 4, NULL), (34, 4, NULL), (35, 4, NULL),
-- Inserting 10 tables for 8 members
(36, 8, NULL), (37, 8, NULL), (38, 8, NULL), (39, 8, NULL), (40, 8, NULL),
(41, 8, NULL), (42, 8, NULL), (43, 8, NULL), (44, 8, NULL), (45, 8, NULL);
INSERT INTO MenuItems (menu_item_id, name, price, category) VALUES
-- Starters
(1, 'Truffle Risotto', 1500.00, 'Starter'),
(2, 'Lobster Bisque', 1200.00, 'Soup'),
(3, 'Wild Mushroom Tart', 1000.00, 'Starter'),
(4, 'Beluga Caviar with Blinis and Crème Fraîche', 9000.00, 'Starter'),
(5, 'Oysters Rockefeller', 5000.00, 'Starter'),
(6, 'Foie Gras Terrine with Brioche', 7000.00, 'Starter'),
(7, 'Carpaccio of Wagyu Beef with Truffle Oil', 8500.00, 'Starter'),
(8, 'Vegan Sushi with Avocado and Mango', 1200.00, 'Starter'),
(37, 'Vegan Quinoa Salad with Avocado', 900.00, 'Salad'),
-- Main Course
(9, 'Beef Wellington', 3500.00, 'Main Course'),
(10, 'Grilled Salmon with Asparagus', 2200.00, 'Main Course'),
(11, 'Herb-Crusted Rack of Lamb', 4000.00, 'Main Course'),
(12, 'Zucchini Noodles with Pesto (Vegan)', 950.00, 'Main Course'),
(13, 'Coconut Curry with Tofu', 1300.00, 'Main Course'),
(14, 'Maine Lobster Thermidor', 9500.00, 'Main Course'),
(15, 'Seared A5 Kobe Beef with Red Wine Reduction', 15000.00, 'Main Course'),
(16, 'Roast Duck with Orange and Grand Marnier Sauce', 5000.00, 'Main Course'),
(17, 'Chilean Sea Bass with Lemon Butter Sauce', 5500.00, 'Main Course'),
(18, 'Roasted Cauliflower Steak with Chimichurri Sauce', 1800.00, 'Main Course'),
(19, 'Grilled Lobster Tail with Garlic Butter', 7500.00, 'Main Course'),
(20, 'King Crab Legs with Herb Butter', 10000.00, 'Main Course'),
(21, 'Chicken Tikka Masala', 1800.00, 'Main Course'),
(22, 'Grilled Shrimp Skewers', 2200.00, 'Main Course'),
-- Desserts
(23, 'Chocolate Fondant with Vanilla Ice Cream', 800.00, 'Dessert'),
(24, 'Crème Brûlée', 600.00, 'Dessert'),
(25, 'Vegan Chocolate Cake', 750.00, 'Dessert'),
(26, 'Tiramisu', 700.00, 'Dessert'),
(27, 'Gold Leaf Topped Chocolate Éclair', 2500.00, 'Dessert'),
(28, 'Raspberry Macaron with Champagne Sorbet', 2000.00, 'Dessert'),
(29, 'Grand Marnier Soufflé', 1800.00, 'Dessert'),
(30, 'Vegan Chocolate and Hazelnut Tart', 1300.00, 'Dessert'),
-- Drinks
(31, 'Signature Mojito', 400.00, 'Drink'),
(32, 'Classic Martini', 500.00, 'Drink'),
(33, 'Champagne (Luxury Label)', 8000.00, 'Drink'),
(34, 'Château Margaux 2015 (Red Wine)', 120000.00, 'Drink'),
(35, 'Dom Pérignon Vintage 2008', 35000.00, 'Drink'),
(36, 'Louis XIII Cognac', 280000.00, 'Drink');
INSERT INTO Eventz (event_id, event_name, price, max_guests) VALUES 
(1, 'Christmas', 50000.00, 100),
(2, 'Easter', 40000.00, 80),
(3, 'Good Friday', 30000.00, 50),
(4, 'New Year', 60000.00, 150),
(5, 'Valentine\'s Day', 45000.00, 70),
(6, 'Halloween', 35000.00, 60),
(7, 'Thanksgiving', 55000.00, 120),
(8, 'Diwali', 50000.00, 100),
(9, 'Hanukkah', 45000.00, 80),
(10, 'Eid', 50000.00, 90);