USE master;
GO
DROP DATABASE IF EXISTS LocalDeliveryMarketplace_Team_28;
GO

CREATE DATABASE LocalDeliveryMarketplace_Team_28;
GO
USE LocalDeliveryMarketplace_Team_28;
GO

-- ============================================================================
-- Section 4.1: Basic Structure of the Database
-- ============================================================================

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.createAllTables AS
	CREATE TABLE dbo.Zone(
		zone_id INT IDENTITY(1, 1),
		zone_name VARCHAR(50) NOT NULL UNIQUE,
		delivery_fee DECIMAL(10, 2) NOT NULL CHECK (delivery_fee >= 0),
		
		CONSTRAINT PK_Zone PRIMARY KEY (zone_id)
	);
	CREATE TABLE dbo.Users(
		user_id INT IDENTITY(1, 1),
		first_name VARCHAR(30) NOT NULL,
		middle_name VARCHAR(30),
		last_name VARCHAR(30) NOT NULL,
		username VARCHAR(30) NOT NULL UNIQUE,
		password VARCHAR(30) NOT NULL,
		email VARCHAR(100) NOT NULL UNIQUE,
		dob DATE,
		account_status VARCHAR(20) NOT NULL DEFAULT 'Active',
		
		CONSTRAINT PK_Users PRIMARY KEY (user_id)
	);
	CREATE TABLE dbo.User_Phone(
		user_id INT,
		phone CHAR(11),

		CONSTRAINT PK_User_Phone PRIMARY KEY (user_id, phone),
		CONSTRAINT FK_User_Phone_User FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id)
	);
	CREATE TABLE dbo.Admin(
		admin_id INT,
		role VARCHAR(20) NOT NULL DEFAULT 'Super Admin',
		zone_id INT,

		CONSTRAINT PK_Admin PRIMARY KEY (admin_id),
		CONSTRAINT FK_Admin_User FOREIGN KEY (admin_id) REFERENCES dbo.Users(user_id),
		CONSTRAINT FK_Admin_Zone FOREIGN KEY (zone_id) REFERENCES dbo.Zone(zone_id)
	);
	CREATE TABLE dbo.Partner(
		partner_id INT,

		CONSTRAINT PK_Partner PRIMARY KEY (partner_id),
		CONSTRAINT FK_Partner_User FOREIGN KEY (partner_id) REFERENCES dbo.Users(user_id)
	);
	CREATE TABLE dbo.Rider(
		rider_id INT,
		vehicle_type VARCHAR(30) NOT NULL,
		plate_no VARCHAR(15) NOT NULL UNIQUE,
		license_no VARCHAR(20) NOT NULL UNIQUE,
		is_available BIT NOT NULL DEFAULT 1,
		zone_id INT NOT NULL,

		CONSTRAINT PK_Rider PRIMARY KEY (rider_id),
		CONSTRAINT FK_Rider_User FOREIGN KEY (rider_id) REFERENCES dbo.Users(user_id),
		CONSTRAINT FK_Rider_Zone FOREIGN KEY (zone_id) REFERENCES dbo.Zone(zone_id)
	);
	CREATE TABLE dbo.Customer(
		customer_id INT,
		wallet_balance DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0),

		CONSTRAINT PK_Customer PRIMARY KEY (customer_id),
		CONSTRAINT FK_Customer_User FOREIGN KEY (customer_id) REFERENCES dbo.Users(user_id)
	);
	CREATE TABLE dbo.Address(
		address_id INT IDENTITY(1, 1),
		description VARCHAR(150) NOT NULL,
		is_active BIT NOT NULL DEFAULT 1,
		customer_id INT NOT NULL,
		zone_id INT NOT NULL,

		CONSTRAINT PK_Address PRIMARY KEY (address_id),
		CONSTRAINT FK_Address_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT FK_Address_Zone FOREIGN KEY (zone_id) REFERENCES dbo.Zone(zone_id)
	);
	CREATE TABLE dbo.Card(
		card_id INT IDENTITY(1, 1),
		card_no CHAR(16) NOT NULL,
		card_holder_name VARCHAR(100) NOT NULL,
		expiration_date DATE NOT NULL,
		customer_id INT NOT NULL,

		CONSTRAINT PK_Card PRIMARY KEY (card_id),
		CONSTRAINT FK_Card_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT UQ_Card_Customer_CardNo UNIQUE (customer_id, card_no)
	);
	CREATE TABLE dbo.Business(
		business_id INT IDENTITY(1, 1),
		name VARCHAR(100) NOT NULL,
		description VARCHAR(255),
		link_website VARCHAR(255),
		opening_hour TIME NOT NULL,
		closing_hour TIME NOT NULL,
		expected_delivery_time INT NOT NULL CHECK (expected_delivery_time > 0),
		status VARCHAR(20) NOT NULL DEFAULT 'Pending',
		suspension_reason VARCHAR(255),
		partner_id INT NOT NULL UNIQUE,
		zone_id INT NOT NULL,

		CONSTRAINT PK_Business PRIMARY KEY (business_id),
		CONSTRAINT FK_Business_Partner FOREIGN KEY (partner_id) REFERENCES dbo.Partner(partner_id),
		CONSTRAINT FK_Business_Zone FOREIGN KEY (zone_id) REFERENCES dbo.Zone(zone_id)
	);
	CREATE TABLE dbo.Business_Phone(
		business_id INT,
		phone CHAR(11),

		CONSTRAINT PK_Business_Phone PRIMARY KEY (business_id, phone),
		CONSTRAINT FK_Business_Phone_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id)
	);
	CREATE TABLE dbo.Restaurant(
		business_id INT,
		cuisine_type VARCHAR(50) NOT NULL,
		food_category VARCHAR(50) NOT NULL,

		CONSTRAINT PK_Restaurant PRIMARY KEY (business_id),
		CONSTRAINT FK_Restaurant_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id)
	);
	CREATE TABLE dbo.Pharmacy(
		business_id INT,
		pharmacy_type VARCHAR(50) NOT NULL,

		CONSTRAINT PK_Pharmacy PRIMARY KEY (business_id),
		CONSTRAINT FK_Pharmacy_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id)
	);
	CREATE TABLE dbo.Blacklist(
		customer_id INT,
		admin_id INT NOT NULL,
		reason VARCHAR(255) NOT NULL,

		CONSTRAINT PK_Blacklist PRIMARY KEY (customer_id),
		CONSTRAINT FK_Blacklist_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT FK_Blacklist_Admin FOREIGN KEY (admin_id) REFERENCES dbo.Admin(admin_id)
	);
	CREATE TABLE dbo.Product(
		product_id INT IDENTITY(1, 1),
		name VARCHAR(100) NOT NULL,
		description VARCHAR(255),
		category VARCHAR(50) NOT NULL,
		price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
		discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
		is_available BIT NOT NULL DEFAULT 1,
		business_id INT NOT NULL,

		CONSTRAINT PK_Product PRIMARY KEY (product_id),
		CONSTRAINT FK_Product_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id),
		CONSTRAINT CK_Product_Discount CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price)
	);
	CREATE TABLE dbo.Favorite_Business(
		customer_id INT,
		business_id INT,

		CONSTRAINT PK_Favorite_Business PRIMARY KEY (customer_id, business_id),
		CONSTRAINT FK_Favorite_Business_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT FK_Favorite_Business_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id)
	);
	CREATE TABLE dbo.Favorite_Product(
		customer_id INT,
		product_id INT,

		CONSTRAINT PK_Favorite_Product PRIMARY KEY (customer_id, product_id),
		CONSTRAINT FK_Favorite_Product_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT FK_Favorite_Product_Product FOREIGN KEY (product_id) REFERENCES dbo.Product(product_id)
	);
	CREATE TABLE dbo.Voucher(
		voucher_id INT IDENTITY(1, 1),
		promo_code VARCHAR(30) NOT NULL UNIQUE,
		is_percentage BIT NOT NULL,
		amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
		expiry_date DATE NOT NULL,
		status VARCHAR(20) NOT NULL DEFAULT 'Unused',
		customer_id INT NOT NULL,

		CONSTRAINT PK_Voucher PRIMARY KEY (voucher_id),
		CONSTRAINT FK_Voucher_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id)
	);
	CREATE TABLE dbo.Cart(
		cart_id INT IDENTITY(1, 1),
		status VARCHAR(20) NOT NULL DEFAULT 'Active',
		created_at DATETIME NOT NULL DEFAULT GETDATE(),
		customer_id INT NOT NULL,
		address_id INT NOT NULL,

		CONSTRAINT PK_Cart PRIMARY KEY (cart_id),
		CONSTRAINT FK_Cart_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
		CONSTRAINT FK_Cart_Address FOREIGN KEY (address_id) REFERENCES dbo.Address(address_id)
	);
	CREATE TABLE dbo.CartItem(
		cart_id INT,
		product_id INT,
		quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 10),
		notes VARCHAR(255),
		unit_price DECIMAL(10, 2),

		CONSTRAINT PK_CartItem PRIMARY KEY (cart_id, product_id),
		CONSTRAINT FK_CartItem_Cart FOREIGN KEY (cart_id) REFERENCES dbo.Cart(cart_id),
		CONSTRAINT FK_CartItem_Product FOREIGN KEY (product_id) REFERENCES dbo.Product(product_id)
	);
	CREATE TABLE dbo.Orders(
		order_id INT IDENTITY(1, 1),
		order_date DATETIME NOT NULL,
		status VARCHAR(20) NOT NULL DEFAULT 'Placed',
		discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
		total_amount DECIMAL(10, 2) NOT NULL,
		cart_id INT NOT NULL UNIQUE,
		zone_id INT NOT NULL,
		voucher_id INT,

		CONSTRAINT PK_Orders PRIMARY KEY (order_id),
		CONSTRAINT FK_Orders_Cart FOREIGN KEY (cart_id) REFERENCES dbo.Cart(cart_id),
		CONSTRAINT FK_Orders_Zone FOREIGN KEY (zone_id) REFERENCES dbo.Zone(zone_id),
		CONSTRAINT FK_Orders_Voucher FOREIGN KEY (voucher_id) REFERENCES dbo.Voucher(voucher_id)
	);
	CREATE TABLE dbo.SubOrder(
		suborder_id INT IDENTITY(1, 1),
		status VARCHAR(20) NOT NULL DEFAULT 'Placed',
		total_price DECIMAL(10, 2) NOT NULL,
		delivery_fee DECIMAL(10, 2) NOT NULL,
		order_id INT NOT NULL,
		business_id INT NOT NULL,

		CONSTRAINT PK_SubOrder PRIMARY KEY (suborder_id),
		CONSTRAINT FK_SubOrder_Orders FOREIGN KEY (order_id) REFERENCES dbo.Orders(order_id),
		CONSTRAINT FK_SubOrder_Business FOREIGN KEY (business_id) REFERENCES dbo.Business(business_id),
		CONSTRAINT UQ_SubOrder_Order_Business UNIQUE (order_id, business_id)
	);
	CREATE TABLE dbo.Delivery(
		delivery_id INT IDENTITY(1, 1),
		assigned_at DATETIME NOT NULL,
		picked_up_at DATETIME,
		delivered_at DATETIME,
		tracking_time INT,
		rider_rating INT CHECK (rider_rating BETWEEN 1 AND 5),
		suborder_id INT NOT NULL UNIQUE,
		rider_id INT NOT NULL,

		CONSTRAINT PK_Delivery PRIMARY KEY (delivery_id),
		CONSTRAINT FK_Delivery_SubOrder FOREIGN KEY (suborder_id) REFERENCES dbo.SubOrder(suborder_id),
		CONSTRAINT FK_Delivery_Rider FOREIGN KEY (rider_id) REFERENCES dbo.Rider(rider_id)
	);
	CREATE TABLE dbo.Payment(
		payment_id INT IDENTITY(1, 1),
		amount DECIMAL(10, 2) NOT NULL,
		currency VARCHAR(3) NOT NULL DEFAULT 'EGP',
		method VARCHAR(20) NOT NULL,
		transaction_date DATETIME NOT NULL,
		refunded_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
		order_id INT NOT NULL UNIQUE,
		card_id INT,

		CONSTRAINT PK_Payment PRIMARY KEY (payment_id),
		CONSTRAINT FK_Payment_Orders FOREIGN KEY (order_id) REFERENCES dbo.Orders(order_id),
		CONSTRAINT FK_Payment_Card FOREIGN KEY (card_id) REFERENCES dbo.Card(card_id),
		CONSTRAINT CK_Payment_Refund CHECK (refunded_amount <= amount)
	);
	CREATE TABLE dbo.Feedback(
		feedback_id INT IDENTITY(1, 1),
		headline VARCHAR(100) NOT NULL,
		description VARCHAR(500),
		rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
		feedback_date DATETIME NOT NULL DEFAULT GETDATE(),
		suborder_id INT NOT NULL UNIQUE,

		CONSTRAINT PK_Feedback PRIMARY KEY (feedback_id),
		CONSTRAINT FK_Feedback_SubOrder FOREIGN KEY (suborder_id) REFERENCES dbo.SubOrder(suborder_id)
	);
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.dropAllTables AS
	-- Children before parents.
	DROP TABLE IF EXISTS dbo.Feedback;
	DROP TABLE IF EXISTS dbo.Payment;
	DROP TABLE IF EXISTS dbo.Delivery;
	DROP TABLE IF EXISTS dbo.SubOrder;
	DROP TABLE IF EXISTS dbo.Orders;
	DROP TABLE IF EXISTS dbo.CartItem;
	DROP TABLE IF EXISTS dbo.Cart;
	DROP TABLE IF EXISTS dbo.Voucher;
	DROP TABLE IF EXISTS dbo.Favorite_Product;
	DROP TABLE IF EXISTS dbo.Favorite_Business;
	DROP TABLE IF EXISTS dbo.Product;
	DROP TABLE IF EXISTS dbo.Blacklist;
	DROP TABLE IF EXISTS dbo.Pharmacy;
	DROP TABLE IF EXISTS dbo.Restaurant;
	DROP TABLE IF EXISTS dbo.Business_Phone;
	DROP TABLE IF EXISTS dbo.Business;
	DROP TABLE IF EXISTS dbo.Card;
	DROP TABLE IF EXISTS dbo.Address;
	DROP TABLE IF EXISTS dbo.Customer;
	DROP TABLE IF EXISTS dbo.Rider;
	DROP TABLE IF EXISTS dbo.Partner;
	DROP TABLE IF EXISTS dbo.Admin;
	DROP TABLE IF EXISTS dbo.User_Phone;
	DROP TABLE IF EXISTS dbo.Users;
	DROP TABLE IF EXISTS dbo.Zone;
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.dropAllProceduresFunctionsViews
AS
BEGIN
	SET NOCOUNT ON;

	-- The list comes from the catalog, so helper procedures and functions are dropped too.
	-- @@PROCID is this procedure, which has to stay.
	DECLARE @sql NVARCHAR(MAX) = N'';

	SELECT @sql = @sql
		+ CASE type
			WHEN 'P' THEN N'DROP PROCEDURE '
			WHEN 'V' THEN N'DROP VIEW '
			ELSE N'DROP FUNCTION '
		END
		+ QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N'; '
	FROM sys.objects
	WHERE type IN ('P', 'FN', 'IF', 'TF', 'V')
		AND is_ms_shipped = 0
		AND object_id <> @@PROCID;

	EXEC sp_executesql @sql;

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.clearAllTables
AS
BEGIN
	SET NOCOUNT ON;

	-- Children before parents, the same order as dropAllTables.
	DELETE FROM dbo.Feedback;
	DELETE FROM dbo.Payment;
	DELETE FROM dbo.Delivery;
	DELETE FROM dbo.SubOrder;
	DELETE FROM dbo.Orders;
	DELETE FROM dbo.CartItem;
	DELETE FROM dbo.Cart;
	DELETE FROM dbo.Voucher;
	DELETE FROM dbo.Favorite_Product;
	DELETE FROM dbo.Favorite_Business;
	DELETE FROM dbo.Product;
	DELETE FROM dbo.Blacklist;
	DELETE FROM dbo.Pharmacy;
	DELETE FROM dbo.Restaurant;
	DELETE FROM dbo.Business_Phone;
	DELETE FROM dbo.Business;
	DELETE FROM dbo.Card;
	DELETE FROM dbo.Address;
	DELETE FROM dbo.Customer;
	DELETE FROM dbo.Rider;
	DELETE FROM dbo.Partner;
	DELETE FROM dbo.Admin;
	DELETE FROM dbo.User_Phone;
	DELETE FROM dbo.Users;
	DELETE FROM dbo.Zone;

	-- RESEED 0 makes the next ID 1 only on a table that has had rows. On a table that never had
	-- any it would make the next ID 0, so tables whose last_value is NULL are left alone.
	DECLARE @sql NVARCHAR(MAX) = N'';

	SELECT @sql = @sql + N'DBCC CHECKIDENT (''dbo.' + t.name + N''', RESEED, 0) WITH NO_INFOMSGS; '
	FROM sys.identity_columns ic
	INNER JOIN sys.tables t ON t.object_id = ic.object_id
	WHERE t.schema_id = SCHEMA_ID('dbo')
		AND ic.last_value IS NOT NULL;

	EXEC sp_executesql @sql;

	RETURN 0;
END
GO

-- Views and inline functions check the tables they use when they are created, so build them now.
EXEC dbo.createAllTables;
GO

-- ============================================================================
-- Section 4.2: Basic Data Retrieval (Views)
-- ============================================================================

-- Retag Atef (64-21789)
CREATE VIEW dbo.allBusinessProfiles AS
	SELECT b.business_id,
		b.name AS business_name,
		CAST(CASE
			WHEN r.business_id IS NOT NULL THEN 'Restaurant'
			WHEN ph.business_id IS NOT NULL THEN 'Pharmacy'
		END AS VARCHAR(20)) AS business_type,
		z.zone_name,
		u.first_name + ' ' + u.last_name AS partner_name,
		b.status,
		b.opening_hour,
		b.closing_hour
	FROM dbo.Business b
	INNER JOIN dbo.Zone z ON z.zone_id = b.zone_id
	INNER JOIN dbo.Users u ON u.user_id = b.partner_id
	LEFT JOIN dbo.Restaurant r ON r.business_id = b.business_id
	LEFT JOIN dbo.Pharmacy ph ON ph.business_id = b.business_id;
GO

-- Youssef Maged (64-20178)
CREATE VIEW dbo.BusinessesPerZone AS
	SELECT z.zone_id,
		z.zone_name,
		COUNT(b.business_id) AS business_count
	FROM dbo.Zone z
	LEFT JOIN dbo.Business b
		ON b.zone_id = z.zone_id
		AND b.status = 'Active'
	GROUP BY z.zone_id, z.zone_name;
GO

-- Farida Tarek (64-29168)
CREATE VIEW dbo.BusinessRatingsSummary AS
	SELECT b.business_id,
		b.name AS business_name,
		CAST(AVG(CAST(f.rating AS decimal(10,2))) AS decimal(10,2)) AS avg_rating,
		COUNT(f.feedback_id) AS ratings_count
	FROM dbo.Business b
	LEFT JOIN dbo.SubOrder s ON s.business_id = b.business_id
	LEFT JOIN dbo.Feedback f ON f.suborder_id = s.suborder_id
	GROUP BY b.business_id, b.name;
GO
	
-- Mohamed Amr (64-24301)
CREATE VIEW dbo.ActiveVouchers AS
	SELECT
		voucher_id,
		promo_code,
		customer_id,
		is_percentage,
		amount,
		expiry_date
	FROM dbo.Voucher
	WHERE status = 'Unused'
	  AND expiry_date >= CAST(GETDATE() AS DATE);
GO

-- Retag Atef (64-21789)
CREATE VIEW dbo.PendingBusinessApprovals AS
	SELECT b.business_id,
		b.name AS business_name,
		CAST(CASE
			WHEN r.business_id IS NOT NULL THEN 'Restaurant'
			WHEN ph.business_id IS NOT NULL THEN 'Pharmacy'
		END AS VARCHAR(20)) AS business_type,
		z.zone_name,
		u.first_name + ' ' + u.last_name AS partner_name
	FROM dbo.Business b
	INNER JOIN dbo.Zone z ON z.zone_id = b.zone_id
	INNER JOIN dbo.Users u ON u.user_id = b.partner_id
	LEFT JOIN dbo.Restaurant r ON r.business_id = b.business_id
	LEFT JOIN dbo.Pharmacy ph ON ph.business_id = b.business_id
	WHERE b.status = 'Pending';
GO

-- Farida Tarek (64-29168)
CREATE VIEW dbo.RiderPerformanceSummary AS
	SELECT r.rider_id,
		CAST(u.first_name + ' ' + u.last_name AS varchar(101)) AS rider_name,
		z.zone_name,
		COUNT(CASE WHEN s.status = 'Delivered' THEN 1 END) AS completed_deliveries,
		CAST(AVG(CAST(d.rider_rating AS decimal(10,2))) AS decimal(10,2)) AS avg_rating
	FROM dbo.Rider r
	JOIN dbo.Users u ON u.user_id = r.rider_id
	JOIN dbo.Zone z ON z.zone_id = r.zone_id
	LEFT JOIN dbo.Delivery d ON d.rider_id = r.rider_id
	LEFT JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
	GROUP BY r.rider_id, u.first_name, u.last_name, z.zone_name;
GO

-- Retag Atef (64-21789)
CREATE VIEW dbo.TopSellingProducts AS
	SELECT TOP 10
		p.product_id,
		p.name AS product_name,
		b.name AS business_name,
		CAST(CASE
			WHEN r.business_id IS NOT NULL THEN 'Restaurant'
			WHEN ph.business_id IS NOT NULL THEN 'Pharmacy'
		END AS VARCHAR(20)) AS business_type,
		SUM(ci.quantity) AS units_sold,
		CAST(SUM(ci.quantity * ci.unit_price) AS DECIMAL(10, 2)) AS total_revenue
	FROM dbo.CartItem ci
	INNER JOIN dbo.Orders o ON o.cart_id = ci.cart_id
	INNER JOIN dbo.Product p ON p.product_id = ci.product_id
	-- The SubOrder of the product's business in that order decides whether its units count.
	INNER JOIN dbo.SubOrder s
		ON s.order_id = o.order_id
		AND s.business_id = p.business_id
	INNER JOIN dbo.Business b ON b.business_id = p.business_id
	LEFT JOIN dbo.Restaurant r ON r.business_id = b.business_id
	LEFT JOIN dbo.Pharmacy ph ON ph.business_id = b.business_id
	WHERE s.status <> 'Cancelled'
	GROUP BY p.product_id, p.name, b.name, r.business_id, ph.business_id
	ORDER BY units_sold DESC, p.product_id;
GO

-- Farida Tarek (64-29168)
CREATE VIEW dbo.ZoneDeliveryPerformance AS
	SELECT z.zone_id,
		z.zone_name,
		COUNT(d.delivery_id) AS delivery_count,
		CAST(AVG(CAST(d.tracking_time AS decimal(10,2))) AS decimal(10,2)) AS avg_tracking_time
	FROM dbo.Zone z
	LEFT JOIN dbo.Orders o ON o.zone_id = z.zone_id
	LEFT JOIN dbo.SubOrder s
		ON s.order_id = o.order_id
		AND s.status = 'Delivered'
	LEFT JOIN dbo.Delivery d ON d.suborder_id = s.suborder_id
	GROUP BY z.zone_id, z.zone_name;
GO

-- ============================================================================
-- Section 4.3: Accounts: Registration, Login and Password
-- ============================================================================

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Customer_Register
	@first_name VARCHAR(30),
	@middle_name VARCHAR(30),
	@last_name VARCHAR(30),
	@username VARCHAR(30),
	@password VARCHAR(30),
	@email VARCHAR(100),
	@phone CHAR(11),
	@dob DATE
AS
BEGIN
	SET NOCOUNT ON;

	IF @first_name IS NULL OR @first_name = ''
	   OR @last_name IS NULL OR @last_name = ''
	   OR @username IS NULL OR @username = ''
	   OR @password IS NULL OR @password = ''
	   OR @email IS NULL OR @email = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
	VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

	DECLARE @new_user_id INT = SCOPE_IDENTITY();

	INSERT INTO dbo.User_Phone (user_id, phone)
	VALUES (@new_user_id, @phone);

	INSERT INTO dbo.Customer (customer_id, wallet_balance)
	VALUES (@new_user_id, 0);

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Partner_Register
	@first_name VARCHAR(30),
	@middle_name VARCHAR(30),
	@last_name VARCHAR(30),
	@username VARCHAR(30),
	@password VARCHAR(30),
	@email VARCHAR(100),
	@phone CHAR(11),
	@dob DATE
AS
BEGIN
	SET NOCOUNT ON;

	IF @first_name IS NULL OR @first_name = ''
	   OR @last_name IS NULL OR @last_name = ''
	   OR @username IS NULL OR @username = ''
	   OR @password IS NULL OR @password = ''
	   OR @email IS NULL OR @email = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
	VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

	DECLARE @new_user_id INT = SCOPE_IDENTITY();

	INSERT INTO dbo.User_Phone (user_id, phone)
	VALUES (@new_user_id, @phone);

	INSERT INTO dbo.Partner (partner_id)
	VALUES (@new_user_id);

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Rider_Register
	@first_name VARCHAR(30),
	@middle_name VARCHAR(30),
	@last_name VARCHAR(30),
	@username VARCHAR(30),
	@password VARCHAR(30),
	@email VARCHAR(100),
	@phone CHAR(11),
	@dob DATE,
	@vehicle_type VARCHAR(30),
	@plate_no VARCHAR(15),
	@license_no VARCHAR(20),
	@zone_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @first_name IS NULL OR @first_name = ''
	   OR @last_name IS NULL OR @last_name = ''
	   OR @username IS NULL OR @username = ''
	   OR @password IS NULL OR @password = ''
	   OR @email IS NULL OR @email = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR @vehicle_type IS NULL OR @vehicle_type = ''
	   OR @plate_no IS NULL OR @plate_no = ''
	   OR @license_no IS NULL OR @license_no = ''
	   OR @zone_id IS NULL
	   OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	   OR EXISTS (SELECT 1 FROM dbo.Rider WHERE plate_no = @plate_no OR license_no = @license_no)
	BEGIN
		RETURN -2;
	END

	INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
	VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

	DECLARE @new_user_id INT = SCOPE_IDENTITY();

	INSERT INTO dbo.User_Phone (user_id, phone)
	VALUES (@new_user_id, @phone);

	INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id)
	VALUES (@new_user_id, @vehicle_type, @plate_no, @license_no, 1, @zone_id);

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE FUNCTION dbo.CustomerLoginValidation
(
	@username VARCHAR(30),
	@password VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
	IF @username IS NULL OR @password IS NULL
		RETURN 0;

	IF EXISTS (
		SELECT 1
		FROM dbo.Users u
		INNER JOIN dbo.Customer c ON u.user_id = c.customer_id
		WHERE u.username = @username
		  AND u.password = @password COLLATE Latin1_General_CS_AS -- case-sensitive
		  AND u.account_status = 'Active'
	)
		RETURN 1;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE FUNCTION dbo.PartnerLoginValidation
(
	@username VARCHAR(30),
	@password VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
	IF @username IS NULL OR @password IS NULL
		RETURN 0;

	IF EXISTS (
		SELECT 1
		FROM dbo.Users u
		INNER JOIN dbo.Partner p ON u.user_id = p.partner_id
		WHERE u.username = @username
		  AND u.password = @password COLLATE Latin1_General_CS_AS -- case-sensitive
		  AND u.account_status = 'Active'
	)
		RETURN 1;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE FUNCTION dbo.RiderLoginValidation
(
	@username VARCHAR(30),
	@password VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
	IF @username IS NULL OR @password IS NULL
		RETURN 0;

	IF EXISTS (
		SELECT 1
		FROM dbo.Users u
		INNER JOIN dbo.Rider r ON u.user_id = r.rider_id
		WHERE u.username = @username
		  AND u.password = @password COLLATE Latin1_General_CS_AS -- case-sensitive
		  AND u.account_status = 'Active'
	)
		RETURN 1;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE FUNCTION dbo.AdminLoginValidation
(
	@username VARCHAR(30),
	@password VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
	IF @username IS NULL OR @password IS NULL
		RETURN 0;

	IF EXISTS (
		SELECT 1
		FROM dbo.Users u
		INNER JOIN dbo.Admin a ON u.user_id = a.admin_id
		WHERE u.username = @username
		  AND u.password = @password COLLATE Latin1_General_CS_AS -- case-sensitive
		  AND u.account_status = 'Active'
	)
		RETURN 1;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Change_Password
	@user_id INT,
	@old_password VARCHAR(30),
	@new_password VARCHAR(30),
	@new_password_repeat VARCHAR(30),
	@success BIT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET @success = 0;

	IF @user_id IS NULL
	   OR @old_password IS NULL
	   OR @new_password IS NULL OR @new_password = ''
	   OR @new_password_repeat IS NULL
	   OR @new_password <> @new_password_repeat COLLATE Latin1_General_CS_AS -- case-sensitive
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Users
		WHERE user_id = @user_id
		  AND password = @old_password COLLATE Latin1_General_CS_AS -- case-sensitive
	)
	BEGIN
		RETURN -1;
	END

	UPDATE dbo.Users
	SET password = @new_password
	WHERE user_id = @user_id;

	SET @success = 1;
	RETURN 0;
END
GO

-- ============================================================================
-- Section 4.4: As an Admin, I should be able to:
-- ============================================================================

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Create_Admin
	@first_name VARCHAR(30),
	@middle_name VARCHAR(30),
	@last_name VARCHAR(30),
	@username VARCHAR(30),
	@password VARCHAR(30),
	@email VARCHAR(100),
	@phone CHAR(11),
	@dob DATE,
	@role VARCHAR(20),
	@zone_id INT,
	@super_admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @super_admin_id IS NULL
	   OR NOT EXISTS (
		   SELECT 1
		   FROM dbo.Admin a
		   INNER JOIN dbo.Users u ON u.user_id = a.admin_id
		   WHERE a.admin_id = @super_admin_id
		     AND a.role = 'Super Admin'
		     AND u.account_status = 'Active'
	   )
	BEGIN
		RETURN -3;
	END

	-- NULL means Super Admin. Stored exactly as spelled in Section 2.3, whatever case the caller used.
	DECLARE @effective_role VARCHAR(20) = CASE ISNULL(@role, 'Super Admin') WHEN 'Super Admin' THEN 'Super Admin' WHEN 'Zone Admin' THEN 'Zone Admin' END;

	IF @first_name IS NULL OR @first_name = ''
	   OR @last_name IS NULL OR @last_name = ''
	   OR @username IS NULL OR @username = ''
	   OR @password IS NULL OR @password = ''
	   OR @email IS NULL OR @email = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	   OR @effective_role IS NULL
	   OR (@effective_role = 'Super Admin' AND @zone_id IS NOT NULL)
	   OR (@effective_role = 'Zone Admin' AND (@zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
	VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

	DECLARE @new_user_id INT = SCOPE_IDENTITY();

	INSERT INTO dbo.User_Phone (user_id, phone)
	VALUES (@new_user_id, @phone);

	INSERT INTO dbo.Admin (admin_id, role, zone_id)
	VALUES (@new_user_id, @effective_role, @zone_id);

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Approve_Business
	@business_id INT,
	@admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL OR @admin_id IS NULL
		RETURN -1;

	DECLARE @b_status VARCHAR(20), @b_zone INT;
	SELECT @b_status = status, @b_zone = zone_id
	FROM dbo.Business
	WHERE business_id = @business_id;

	IF @b_status IS NULL
		RETURN -1;

	DECLARE @a_role VARCHAR(20), @a_zone INT;
	SELECT @a_role = a.role, @a_zone = a.zone_id
	FROM dbo.Admin a
	INNER JOIN dbo.Users u ON u.user_id = a.admin_id
	WHERE a.admin_id = @admin_id
	  AND u.account_status = 'Active';

	IF @a_role IS NULL
		RETURN -3;

	IF @a_role = 'Zone Admin' AND (@a_zone IS NULL OR @a_zone <> @b_zone)
		RETURN -3;

	IF @b_status <> 'Pending'
		RETURN -4;

	UPDATE dbo.Business
	SET status = 'Active'
	WHERE business_id = @business_id;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Reject_Business
	@business_id INT,
	@admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL OR @admin_id IS NULL
		RETURN -1;

	DECLARE @b_status VARCHAR(20), @b_zone INT;
	SELECT @b_status = status, @b_zone = zone_id
	FROM dbo.Business
	WHERE business_id = @business_id;

	IF @b_status IS NULL
		RETURN -1;

	DECLARE @a_role VARCHAR(20), @a_zone INT;
	SELECT @a_role = a.role, @a_zone = a.zone_id
	FROM dbo.Admin a
	INNER JOIN dbo.Users u ON u.user_id = a.admin_id
	WHERE a.admin_id = @admin_id
	  AND u.account_status = 'Active';

	IF @a_role IS NULL
		RETURN -3;

	IF @a_role = 'Zone Admin' AND (@a_zone IS NULL OR @a_zone <> @b_zone)
		RETURN -3;

	IF @b_status <> 'Pending'
		RETURN -4;

	UPDATE dbo.Business
	SET status = 'Rejected'
	WHERE business_id = @business_id;

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.Suspend_Business
	@business_id INT,
	@admin_id INT,
	@reason VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL OR @admin_id IS NULL
		OR @reason IS NULL OR @reason = ''
		RETURN -1;

	DECLARE @b_status VARCHAR(20), @b_zone INT;
	SELECT @b_status = status, @b_zone = zone_id
	FROM dbo.Business
	WHERE business_id = @business_id;

	IF @b_status IS NULL
		RETURN -1;

	DECLARE @a_role VARCHAR(20), @a_zone INT;
	SELECT @a_role = a.role, @a_zone = a.zone_id
	FROM dbo.Admin a
	INNER JOIN dbo.Users u ON u.user_id = a.admin_id
	WHERE a.admin_id = @admin_id
		AND u.account_status = 'Active';

	-- BR-3: a Zone Admin may only suspend businesses of their own zone.
	IF @a_role IS NULL
		OR (@a_role = 'Zone Admin' AND (@a_zone IS NULL OR @a_zone <> @b_zone))
		RETURN -3;

	IF @b_status <> 'Active'
		RETURN -4;

	-- The SubOrders to cancel and their refund (BR-14): total_price + delivery_fee, capped at what is
	-- left of the payment. A business has at most one SubOrder per order (UNIQUE (order_id, business_id)),
	-- so every row is a different order.
	DECLARE @cancelled TABLE (
		suborder_id INT,
		order_id INT,
		customer_id INT,
		method VARCHAR(20),
		refund DECIMAL(10, 2)
	);

	INSERT INTO @cancelled (suborder_id, order_id, customer_id, method, refund)
	SELECT s.suborder_id,
		s.order_id,
		c.customer_id,
		p.method,
		CASE
			WHEN p.payment_id IS NULL THEN 0
			WHEN s.total_price + s.delivery_fee < p.amount - p.refunded_amount THEN s.total_price + s.delivery_fee
			ELSE p.amount - p.refunded_amount
		END
	FROM dbo.SubOrder s
	INNER JOIN dbo.Orders o ON o.order_id = s.order_id
	INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
	LEFT JOIN dbo.Payment p ON p.order_id = s.order_id
	WHERE s.business_id = @business_id
		AND s.status IN ('Placed', 'Assigned');

	UPDATE dbo.Business
	SET status = 'Suspended',
		suspension_reason = @reason
	WHERE business_id = @business_id;

	UPDATE dbo.Product
	SET is_available = 0
	WHERE business_id = @business_id;

	UPDATE p
	SET refunded_amount = p.refunded_amount + x.refund
	FROM dbo.Payment p
	INNER JOIN @cancelled x ON x.order_id = p.order_id;

	-- Refunds go to the wallet unless the order was paid in cash. A customer can have several
	-- affected orders, so the refunds are added up per customer first.
	UPDATE cu
	SET wallet_balance = cu.wallet_balance + x.refund
	FROM dbo.Customer cu
	INNER JOIN (
		SELECT customer_id, SUM(refund) AS refund
		FROM @cancelled
		WHERE method <> 'Cash'
		GROUP BY customer_id
	) x ON x.customer_id = cu.customer_id;

	UPDATE dbo.SubOrder
	SET status = 'Cancelled'
	WHERE suborder_id IN (SELECT suborder_id FROM @cancelled);

	-- BR-11: recompute the status of every affected order.
	UPDATE o
	SET status = CASE
		WHEN NOT EXISTS (SELECT 1 FROM dbo.SubOrder s WHERE s.order_id = o.order_id AND s.status <> 'Cancelled')
			THEN 'Cancelled'
		WHEN NOT EXISTS (SELECT 1 FROM dbo.SubOrder s WHERE s.order_id = o.order_id AND s.status NOT IN ('Cancelled', 'Delivered'))
			THEN 'Delivered'
		WHEN EXISTS (SELECT 1 FROM dbo.SubOrder s WHERE s.order_id = o.order_id AND s.status IN ('Picked Up', 'Delivered'))
			THEN 'In Progress'
		ELSE 'Placed'
	END
	FROM dbo.Orders o
	WHERE o.order_id IN (SELECT order_id FROM @cancelled);

	-- An order that is now cancelled entirely gets its voucher back, as in Cancel_Order.
	UPDATE dbo.Voucher
	SET status = 'Unused'
	WHERE voucher_id IN (
		SELECT voucher_id
		FROM dbo.Orders
		WHERE status = 'Cancelled'
			AND order_id IN (SELECT order_id FROM @cancelled)
	);

	UPDATE dbo.Orders
	SET voucher_id = NULL
	WHERE status = 'Cancelled'
		AND order_id IN (SELECT order_id FROM @cancelled);

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.Reinstate_Business
	@business_id INT,
	@super_admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL OR @super_admin_id IS NULL
		RETURN -1;

	DECLARE @b_status VARCHAR(20);
	SELECT @b_status = status
	FROM dbo.Business
	WHERE business_id = @business_id;

	IF @b_status IS NULL
		RETURN -1;

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Admin a
		INNER JOIN dbo.Users u ON u.user_id = a.admin_id
		WHERE a.admin_id = @super_admin_id
			AND a.role = 'Super Admin'
			AND u.account_status = 'Active'
	)
		RETURN -3;

	IF @b_status <> 'Suspended'
		RETURN -4;

	-- The products stay unavailable until the partner re-enables them (Toggle_Product_Status).
	UPDATE dbo.Business
	SET status = 'Active',
		suspension_reason = NULL
	WHERE business_id = @business_id;

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.Create_Zone
	@zone_name VARCHAR(50),
	@delivery_fee DECIMAL(10, 2),
	@super_admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @super_admin_id IS NULL
		OR NOT EXISTS (
			SELECT 1
			FROM dbo.Admin a
			INNER JOIN dbo.Users u ON u.user_id = a.admin_id
			WHERE a.admin_id = @super_admin_id
				AND a.role = 'Super Admin'
				AND u.account_status = 'Active'
		)
		RETURN -3;

	IF @zone_name IS NULL OR @zone_name = ''
		OR @delivery_fee IS NULL OR @delivery_fee < 0
		RETURN -1;

	IF EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_name = @zone_name)
		RETURN -2;

	INSERT INTO dbo.Zone (zone_name, delivery_fee)
	VALUES (@zone_name, @delivery_fee);

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE PROCEDURE dbo.Update_Zone_Fee
	@zone_id INT,
	@new_fee DECIMAL(10, 2),
	@super_admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @super_admin_id IS NULL
		OR NOT EXISTS (
			SELECT 1
			FROM dbo.Admin a
			INNER JOIN dbo.Users u ON u.user_id = a.admin_id
			WHERE a.admin_id = @super_admin_id
				AND a.role = 'Super Admin'
				AND u.account_status = 'Active'
		)
		RETURN -3;

	IF @zone_id IS NULL
		OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)
		OR @new_fee IS NULL OR @new_fee < 0
		RETURN -1;

	-- Existing SubOrders keep the fee they were created with (SubOrder.delivery_fee).
	UPDATE dbo.Zone
	SET delivery_fee = @new_fee
	WHERE zone_id = @zone_id;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Assign_Admin_Zone
	@admin_id INT,
	@zone_id INT,
	@super_admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @super_admin_id IS NULL
	   OR NOT EXISTS (
		   SELECT 1
		   FROM dbo.Admin a
		   INNER JOIN dbo.Users u ON u.user_id = a.admin_id
		   WHERE a.admin_id = @super_admin_id
		     AND a.role = 'Super Admin'
		     AND u.account_status = 'Active'
	   )
	BEGIN
		RETURN -3;
	END

	IF @admin_id IS NULL OR @zone_id IS NULL
	   OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Admin WHERE admin_id = @admin_id)
	BEGIN
		RETURN -3;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Admin WHERE admin_id = @admin_id AND role = 'Zone Admin')
	BEGIN
		RETURN -1;
	END

	UPDATE dbo.Admin
	SET zone_id = @zone_id
	WHERE admin_id = @admin_id;

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Issue_Voucher
	@customer_id INT,
	@promo_code VARCHAR(30),
	@is_percentage BIT,
	@amount DECIMAL(10, 2),
	@expiry_date DATE,
	@admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @admin_id IS NULL
	   OR NOT EXISTS (
		   SELECT 1
		   FROM dbo.Admin a
		   INNER JOIN dbo.Users u ON u.user_id = a.admin_id
		   WHERE a.admin_id = @admin_id
		     AND u.account_status = 'Active'
	   )
	BEGIN
		RETURN -3;
	END

	IF @customer_id IS NULL
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -3;
	END

	IF EXISTS (
		SELECT 1
		FROM dbo.Users
		WHERE user_id = @customer_id
		  AND account_status = 'Blacklisted'
	)
	BEGIN
		RETURN -3;
	END

	IF @promo_code IS NULL OR @promo_code = ''
	   OR @is_percentage IS NULL
	   OR @amount IS NULL OR @amount <= 0
	   OR (@is_percentage = 1 AND (@amount < 1 OR @amount > 100))
	   OR @expiry_date IS NULL OR @expiry_date < CAST(GETDATE() AS DATE)
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Voucher WHERE promo_code = @promo_code)
	BEGIN
		RETURN -2;
	END

	INSERT INTO dbo.Voucher (promo_code, is_percentage, amount, expiry_date, status, customer_id)
	VALUES (@promo_code, @is_percentage, @amount, @expiry_date, 'Unused', @customer_id);

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Blacklist_Customer
	@customer_id INT,
	@admin_id INT,
	@reason VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @admin_id IS NULL
	   OR @reason IS NULL OR @reason = ''
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -3;
	END

	DECLARE @a_role VARCHAR(20), @a_zone INT;
	SELECT @a_role = a.role, @a_zone = a.zone_id
	FROM dbo.Admin a
	INNER JOIN dbo.Users u ON u.user_id = a.admin_id
	WHERE a.admin_id = @admin_id
	  AND u.account_status = 'Active';

	IF @a_role IS NULL
		RETURN -3;

	DECLARE @c_status VARCHAR(20);
	SELECT @c_status = account_status
	FROM dbo.Users
	WHERE user_id = @customer_id;

	IF @c_status = 'Blacklisted'
	   OR EXISTS (SELECT 1 FROM dbo.Blacklist WHERE customer_id = @customer_id)
	BEGIN
		RETURN -4;
	END

	IF @a_role = 'Zone Admin'
	   AND NOT EXISTS (
		   SELECT 1
		   FROM dbo.Address
		   WHERE customer_id = @customer_id
		     AND zone_id = @a_zone
	   )
	BEGIN
		RETURN -3;
	END

	UPDATE dbo.Users
	SET account_status = 'Blacklisted'
	WHERE user_id = @customer_id;

	INSERT INTO dbo.Blacklist (customer_id, admin_id, reason)
	VALUES (@customer_id, @admin_id, @reason);

	DECLARE @wallet_refund DECIMAL(10, 2);
	SELECT @wallet_refund = ISNULL(SUM(amount - refunded_amount), 0)
	FROM dbo.Payment
	WHERE method <> 'Cash'
	  AND amount > refunded_amount
	  AND order_id IN (
		  SELECT o.order_id
		  FROM dbo.Orders o
		  INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		  WHERE c.customer_id = @customer_id
		    AND o.status <> 'Cancelled'
		    AND NOT EXISTS (
				SELECT 1
				FROM dbo.SubOrder s
				WHERE s.order_id = o.order_id
				  AND s.status IN ('Picked Up', 'Delivered')
			)
	  );

	UPDATE dbo.Payment
	SET refunded_amount = amount
	WHERE amount > refunded_amount
	  AND order_id IN (
		  SELECT o.order_id
		  FROM dbo.Orders o
		  INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		  WHERE c.customer_id = @customer_id
		    AND o.status <> 'Cancelled'
		    AND NOT EXISTS (
				SELECT 1
				FROM dbo.SubOrder s
				WHERE s.order_id = o.order_id
				  AND s.status IN ('Picked Up', 'Delivered')
			)
	  );

	IF @wallet_refund > 0
	BEGIN
		UPDATE dbo.Customer
		SET wallet_balance = wallet_balance + @wallet_refund
		WHERE customer_id = @customer_id;
	END

	UPDATE dbo.Voucher
	SET status = 'Unused'
	WHERE voucher_id IN (
		SELECT o.voucher_id
		FROM dbo.Orders o
		INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		WHERE c.customer_id = @customer_id
		  AND o.status <> 'Cancelled'
		  AND o.voucher_id IS NOT NULL
		  AND NOT EXISTS (
			  SELECT 1
			  FROM dbo.SubOrder s
			  WHERE s.order_id = o.order_id
			    AND s.status IN ('Picked Up', 'Delivered')
		  )
	);

	UPDATE dbo.SubOrder
	SET status = 'Cancelled'
	WHERE status IN ('Placed', 'Assigned')
	  AND order_id IN (
		  SELECT o.order_id
		  FROM dbo.Orders o
		  INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		  WHERE c.customer_id = @customer_id
		    AND o.status <> 'Cancelled'
		    AND NOT EXISTS (
				SELECT 1
				FROM dbo.SubOrder s
				WHERE s.order_id = o.order_id
				  AND s.status IN ('Picked Up', 'Delivered')
			)
	  );

	UPDATE dbo.Orders
	SET status = 'Cancelled',
	    voucher_id = NULL
	WHERE order_id IN (
		SELECT o.order_id
		FROM dbo.Orders o
		INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		WHERE c.customer_id = @customer_id
		  AND o.status <> 'Cancelled'
		  AND NOT EXISTS (
			  SELECT 1
			  FROM dbo.SubOrder s
			  WHERE s.order_id = o.order_id
			    AND s.status IN ('Picked Up', 'Delivered')
		  )
	);

	DELETE FROM dbo.Voucher
	WHERE customer_id = @customer_id
	  AND status = 'Unused';

	RETURN 0;
END
GO

-- Mohamed Amr (64-24301)
CREATE PROCEDURE dbo.Lift_Customer_Blacklist
	@customer_id INT,
	@admin_id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @admin_id IS NULL
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -3;
	END

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Admin a
		INNER JOIN dbo.Users u ON u.user_id = a.admin_id
		WHERE a.admin_id = @admin_id
		  AND u.account_status = 'Active'
	)
	BEGIN
		RETURN -3;
	END

	DECLARE @c_status VARCHAR(20);
	SELECT @c_status = account_status
	FROM dbo.Users
	WHERE user_id = @customer_id;

	IF @c_status <> 'Blacklisted'
	   OR NOT EXISTS (SELECT 1 FROM dbo.Blacklist WHERE customer_id = @customer_id)
	BEGIN
		RETURN -4;
	END

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Blacklist
		WHERE customer_id = @customer_id
		  AND admin_id = @admin_id
	)
	BEGIN
		RETURN -3;
	END

	DELETE FROM dbo.Blacklist
	WHERE customer_id = @customer_id;

	UPDATE dbo.Users
	SET account_status = 'Active'
	WHERE user_id = @customer_id;

	RETURN 0;
END
GO

-- Youssef Maged (64-20178)
CREATE FUNCTION dbo.ZoneOrderReport
(
	@zone_id INT,
	@from_date DATE,
	@to_date DATE
)
RETURNS TABLE
AS
RETURN
(
	SELECT z.zone_id,
		z.zone_name,
		COUNT(o.order_id) AS number_of_orders,
		CAST(AVG(o.total_amount) AS DECIMAL(10, 2)) AS avg_order_total,
		CAST(ISNULL(SUM(o.commission), 0) AS DECIMAL(10, 2)) AS platform_commission
	FROM dbo.Zone z
	LEFT JOIN (
		-- Non-cancelled orders of the period, each with 10% of its non-cancelled SubOrders.
		SELECT ord.order_id,
			ord.zone_id,
			ord.total_amount,
			0.10 * (
				SELECT ISNULL(SUM(s.total_price), 0)
				FROM dbo.SubOrder s
				WHERE s.order_id = ord.order_id
					AND s.status <> 'Cancelled'
			) AS commission
		FROM dbo.Orders ord
		WHERE ord.status <> 'Cancelled'
			AND CAST(ord.order_date AS DATE) BETWEEN @from_date AND @to_date
	) o ON o.zone_id = z.zone_id
	WHERE z.zone_id = @zone_id
		AND @from_date <= @to_date
	GROUP BY z.zone_id, z.zone_name
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.TopRiders (@from_date date, @to_date date)
RETURNS TABLE
AS
RETURN 
(
    SELECT TOP 5
		1 + COUNT(b.rider_id) AS rider_rank,
		a.rider_id,
		a.rider_name,
		a.cnt AS completed_delivery_count
    FROM (SELECT r.rider_id,
			CAST(u.first_name + ' ' + u.last_name AS varchar(101)) AS rider_name,
			COUNT(*) AS cnt
          FROM dbo.Rider r
          JOIN dbo.Users u ON u.user_id = r.rider_id
          JOIN dbo.Delivery d ON d.rider_id = r.rider_id
          JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
          WHERE s.status = 'Delivered'
			AND CAST(d.delivered_at AS date) BETWEEN @from_date AND @to_date
			AND @from_date <= @to_date
          GROUP BY r.rider_id, u.first_name, u.last_name) a
    LEFT JOIN (SELECT d.rider_id, COUNT(*) AS cnt
               FROM dbo.Delivery d
               JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
               WHERE s.status = 'Delivered'
                 AND CAST(d.delivered_at AS date) BETWEEN @from_date AND @to_date
               GROUP BY d.rider_id) b
           ON b.cnt > a.cnt
           OR (b.cnt = a.cnt AND b.rider_id < a.rider_id)
    GROUP BY a.rider_id, a.rider_name, a.cnt
    ORDER BY a.cnt DESC, a.rider_id
);
GO

-- Youssef Maged (64-20178)
CREATE FUNCTION dbo.Daily_Revenue_Report
(
	@report_date DATE
)
RETURNS TABLE
AS
RETURN
(
	SELECT x.zone_name,
		x.business_type,
		COUNT(*) AS number_of_suborders,
		CAST(SUM(x.total_price) AS DECIMAL(10, 2)) AS gross_sales,
		CAST(SUM(x.delivery_fee) AS DECIMAL(10, 2)) AS delivery_fees,
		CAST(0.10 * SUM(x.total_price) AS DECIMAL(10, 2)) AS platform_commission
	FROM (
		SELECT z.zone_name,
			CAST(CASE
				WHEN r.business_id IS NOT NULL THEN 'Restaurant'
				WHEN ph.business_id IS NOT NULL THEN 'Pharmacy'
			END AS VARCHAR(20)) AS business_type,
			s.total_price,
			s.delivery_fee
		FROM dbo.SubOrder s
		INNER JOIN dbo.Orders o ON o.order_id = s.order_id
		INNER JOIN dbo.Zone z ON z.zone_id = o.zone_id
		LEFT JOIN dbo.Restaurant r ON r.business_id = s.business_id
		LEFT JOIN dbo.Pharmacy ph ON ph.business_id = s.business_id
		WHERE s.status <> 'Cancelled'
			AND CAST(o.order_date AS DATE) = @report_date
	) x
	GROUP BY x.zone_name, x.business_type
);
GO

-- ============================================================================
-- Section 4.5: As a Partner, I should be able to:
-- ============================================================================

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Register_Business
	@partner_id INT,
	@name VARCHAR(100),
	@description VARCHAR(255),
	@link_website VARCHAR(255),
	@zone_id INT,
	@opening_hour TIME,
	@closing_hour TIME,
	@expected_delivery_time INT,
	@phone CHAR(11),
	@business_type VARCHAR(20),
	@cuisine_type VARCHAR(50),
	@food_category VARCHAR(50),
	@pharmacy_type VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	IF @partner_id IS NULL
		OR @name IS NULL OR @name = ''
		OR @zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)
		OR @opening_hour IS NULL OR @closing_hour IS NULL
		OR @expected_delivery_time IS NULL OR @expected_delivery_time <= 0
		OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
		OR @business_type IS NULL OR @business_type NOT IN ('Restaurant', 'Pharmacy')
		RETURN -1;

	-- A Restaurant needs cuisine_type and food_category, a Pharmacy needs pharmacy_type.
	IF (@business_type = 'Restaurant' AND (ISNULL(@cuisine_type, '') = '' OR ISNULL(@food_category, '') = ''))
		OR (@business_type = 'Pharmacy' AND ISNULL(@pharmacy_type, '') = '')
		RETURN -1;

	IF NOT EXISTS (SELECT 1 FROM dbo.Partner WHERE partner_id = @partner_id)
		RETURN -3;

	DECLARE @business_id INT, @status VARCHAR(20);
	SELECT @business_id = business_id, @status = status
	FROM dbo.Business
	WHERE partner_id = @partner_id;

	-- A partner owns at most one business. Only a Rejected one may be registered again.
	IF @business_id IS NOT NULL AND @status <> 'Rejected'
		RETURN -2;

	IF @business_id IS NULL
	BEGIN
		INSERT INTO dbo.Business (name, description, link_website, opening_hour, closing_hour,
			expected_delivery_time, status, suspension_reason, partner_id, zone_id)
		VALUES (@name, @description, @link_website, @opening_hour, @closing_hour,
			@expected_delivery_time, 'Pending', NULL, @partner_id, @zone_id);

		SET @business_id = SCOPE_IDENTITY();
	END
	ELSE
	BEGIN
		-- Registering a Rejected business again reuses its row: new data, phones and subtype, back to Pending.
		UPDATE dbo.Business
		SET name = @name,
			description = @description,
			link_website = @link_website,
			opening_hour = @opening_hour,
			closing_hour = @closing_hour,
			expected_delivery_time = @expected_delivery_time,
			status = 'Pending',
			suspension_reason = NULL,
			zone_id = @zone_id
		WHERE business_id = @business_id;

		DELETE FROM dbo.Business_Phone WHERE business_id = @business_id;
		DELETE FROM dbo.Restaurant WHERE business_id = @business_id;
		DELETE FROM dbo.Pharmacy WHERE business_id = @business_id;
	END

	INSERT INTO dbo.Business_Phone (business_id, phone)
	VALUES (@business_id, @phone);

	IF @business_type = 'Restaurant'
		INSERT INTO dbo.Restaurant (business_id, cuisine_type, food_category)
		VALUES (@business_id, @cuisine_type, @food_category);
	ELSE
		INSERT INTO dbo.Pharmacy (business_id, pharmacy_type)
		VALUES (@business_id, @pharmacy_type);

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Update_Business_Info
	@business_id INT,
	@opening_hour TIME,
	@closing_hour TIME,
	@phone CHAR(11),
	@link_website VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL
		OR NOT EXISTS (SELECT 1 FROM dbo.Business WHERE business_id = @business_id)
		OR @opening_hour IS NULL OR @closing_hour IS NULL
		OR (@phone IS NOT NULL AND (LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'))
		RETURN -1;

	IF EXISTS (SELECT 1 FROM dbo.Business_Phone WHERE business_id = @business_id AND phone = @phone)
		RETURN -2;

	UPDATE dbo.Business
	SET opening_hour = @opening_hour,
		closing_hour = @closing_hour,
		link_website = @link_website
	WHERE business_id = @business_id;

	-- The phone is optional: with NULL only the hours and the website change.
	IF @phone IS NOT NULL
		INSERT INTO dbo.Business_Phone (business_id, phone)
		VALUES (@business_id, @phone);

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Upsert_Product
	@business_id INT,
	@product_id INT,
	@name VARCHAR(100),
	@description VARCHAR(255),
	@category VARCHAR(50),
	@price DECIMAL(10, 2),
	@is_available BIT
AS
BEGIN
	SET NOCOUNT ON;

	IF @business_id IS NULL
		OR NOT EXISTS (SELECT 1 FROM dbo.Business WHERE business_id = @business_id)
		OR (@product_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id))
		RETURN -1;

	IF @product_id IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id AND business_id = @business_id)
		RETURN -3;

	IF EXISTS (SELECT 1 FROM dbo.Business WHERE business_id = @business_id AND status = 'Suspended')
		RETURN -4;

	-- On an update the current discount must stay within 50% of the new price (BR-7).
	IF @name IS NULL OR @name = ''
		OR @category IS NULL OR @category = ''
		OR @price IS NULL OR @price <= 0
		OR @is_available IS NULL
		OR EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id AND discount_amount > 0.5 * @price)
		RETURN -1;

	IF @product_id IS NULL
		INSERT INTO dbo.Product (name, description, category, price, discount_amount, is_available, business_id)
		VALUES (@name, @description, @category, @price, 0, @is_available, @business_id);
	ELSE
		UPDATE dbo.Product
		SET name = @name,
			description = @description,
			category = @category,
			price = @price,
			is_available = @is_available
		WHERE product_id = @product_id;

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Toggle_Product_Status
	@product_id INT,
	@is_available BIT
AS
BEGIN
	SET NOCOUNT ON;

	IF @product_id IS NULL OR @is_available IS NULL
		OR NOT EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id)
		RETURN -1;

	IF @is_available = 1
		AND EXISTS (
			SELECT 1
			FROM dbo.Product p
			INNER JOIN dbo.Business b ON b.business_id = p.business_id
			WHERE p.product_id = @product_id
				AND b.status = 'Suspended'
		)
		RETURN -4;

	UPDATE dbo.Product
	SET is_available = @is_available
	WHERE product_id = @product_id;

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Set_Product_Promotion
	@product_id INT,
	@discount_amount DECIMAL(10, 2)
AS
BEGIN
	SET NOCOUNT ON;

	IF @product_id IS NULL OR @discount_amount IS NULL
		OR NOT EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id)
		RETURN -1;

	-- BR-7: a fixed amount between 0 and 50% of the price. 0 removes the promotion.
	IF @discount_amount < 0
		OR EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @product_id AND @discount_amount > 0.5 * price)
		RETURN -1;

	UPDATE dbo.Product
	SET discount_amount = @discount_amount
	WHERE product_id = @product_id;

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE FUNCTION dbo.BusinessSalesReport
(
	@business_id INT,
	@from_date DATE,
	@to_date DATE
)
RETURNS TABLE
AS
RETURN
(
	SELECT p.product_id,
		p.name AS product_name,
		SUM(ci.quantity) AS units_sold,
		CAST(SUM(ci.quantity * ci.unit_price) AS DECIMAL(10, 2)) AS revenue_per_product
	FROM dbo.SubOrder s
	INNER JOIN dbo.Orders o ON o.order_id = s.order_id
	INNER JOIN dbo.CartItem ci ON ci.cart_id = o.cart_id
	INNER JOIN dbo.Product p
		ON p.product_id = ci.product_id
		AND p.business_id = s.business_id
	WHERE s.business_id = @business_id
		AND s.status <> 'Cancelled'
		AND CAST(o.order_date AS DATE) BETWEEN @from_date AND @to_date
	GROUP BY p.product_id, p.name
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.BusinessFeedbackOverview (@business_id int)
RETURNS TABLE
AS
RETURN 
(
    SELECT CAST(AVG(CAST(f.rating AS decimal(10,2))) AS decimal(10,2)) AS avg_rating,
		COUNT(f.feedback_id) AS number_of_feedbacks,
		COUNT(CASE WHEN f.rating = 5 THEN 1 END) AS five_star,
		COUNT(CASE WHEN f.rating = 4 THEN 1 END) AS four_star,
		COUNT(CASE WHEN f.rating = 3 THEN 1 END) AS three_star,
		COUNT(CASE WHEN f.rating = 2 THEN 1 END) AS two_star,
		COUNT(CASE WHEN f.rating = 1 THEN 1 END) AS one_star
    FROM dbo.Business b
    LEFT JOIN dbo.SubOrder s ON s.business_id = b.business_id
    LEFT JOIN dbo.Feedback f ON f.suborder_id = s.suborder_id
    WHERE b.business_id = @business_id
    GROUP BY b.business_id
);
GO

-- ============================================================================
-- Section 4.6: As a Customer, I should be able to:
-- ============================================================================

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Add_Customer_Address(
	@customer_id INT,
	@description VARCHAR(150),
	@zone_id INT
) AS
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @description IS NULL OR @description = '' OR @zone_id IS NULL
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
		RETURN -3;

	UPDATE dbo.Address SET is_active = 0 WHERE customer_id = @customer_id;
	INSERT INTO dbo.Address(description, is_active, customer_id, zone_id)
	VALUES (@description, 1, @customer_id, @zone_id);

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Update_Delete_Customer_Address(
	@customer_id INT,
	@address_id INT,
	@description VARCHAR(150),
	@zone_id INT,
	@action VARCHAR(20)
) AS
	SET NOCOUNT ON;

	-- The public tests call the delete action 'Delete'; Section 2.3 calls it 'Remove'. Both are accepted.
	IF @customer_id IS NULL OR @address_id IS NULL OR @action IS NULL OR @action NOT IN ('Update', 'Delete', 'Remove')
		RETURN -1;
	IF @action = 'Update' AND (@description IS NULL OR @description = '' OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id))
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Address WHERE address_id = @address_id)
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Address WHERE address_id = @address_id AND customer_id = @customer_id)
		RETURN -3;
	IF EXISTS (
		SELECT 1
		FROM dbo.Orders o
		JOIN dbo.Cart c ON c.cart_id = o.cart_id
		WHERE c.address_id = @address_id AND o.status IN ('Placed', 'In Progress')
	)
		RETURN -4;
	IF @action <> 'Update' AND EXISTS (SELECT 1 FROM dbo.Cart WHERE address_id = @address_id)
		RETURN -4;

	IF @action = 'Update'
		UPDATE dbo.Address SET description = @description, zone_id = @zone_id WHERE address_id = @address_id;
	ELSE
		DELETE FROM dbo.Address WHERE address_id = @address_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Change_Active_Address(
	@customer_id INT,
	@new_address_id INT
) AS
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @new_address_id IS NULL
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Address WHERE address_id = @new_address_id)
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Address WHERE address_id = @new_address_id AND customer_id = @customer_id)
		RETURN -3;

	-- Carts of the other addresses stay as they are; they can be used again once their address is active.
	UPDATE dbo.Address SET is_active = 0 WHERE customer_id = @customer_id AND address_id <> @new_address_id;
	UPDATE dbo.Address SET is_active = 1 WHERE address_id = @new_address_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Add_Card(
	@customer_id INT,
	@card_no CHAR(16),
	@card_holder_name VARCHAR(100),
	@expiration_date DATE
) AS
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @card_no IS NULL OR @card_holder_name IS NULL OR @card_holder_name = '' OR @expiration_date IS NULL
		RETURN -1;
	IF LEN(@card_no) <> 16 OR @card_no LIKE '%[^0-9]%' OR @expiration_date < CAST(GETDATE() AS DATE)
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
		RETURN -3;
	IF EXISTS (SELECT 1 FROM dbo.Card WHERE customer_id = @customer_id AND card_no = @card_no)
		RETURN -2;

	INSERT INTO dbo.Card(card_no, card_holder_name, expiration_date, customer_id)
	VALUES (@card_no, @card_holder_name, @expiration_date, @customer_id);

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Create_Cart(
	@customer_id INT
) AS
	SET NOCOUNT ON;

	IF @customer_id IS NULL
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
		RETURN -3;
	IF EXISTS (SELECT 1 FROM dbo.Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
		RETURN -3;

	DECLARE @address_id INT;
	SELECT @address_id = address_id FROM dbo.Address WHERE customer_id = @customer_id AND is_active = 1;

	IF @address_id IS NULL
		RETURN -1;
	IF EXISTS (SELECT 1 FROM dbo.Cart WHERE address_id = @address_id AND status = 'Active')
		RETURN -2;

	INSERT INTO dbo.Cart(status, created_at, customer_id, address_id)
	VALUES ('Active', GETDATE(), @customer_id, @address_id);

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Add_To_Cart(
	@cart_id INT,
	@product_id INT,
	@quantity INT,
	@notes VARCHAR(255)
) AS
	SET NOCOUNT ON;

	IF @cart_id IS NULL OR @product_id IS NULL OR @quantity IS NULL OR @quantity < 1
		RETURN -1;

	DECLARE @cart_status VARCHAR(20), @address_active BIT, @address_zone INT;
	SELECT @cart_status = c.status, @address_active = a.is_active, @address_zone = a.zone_id
	FROM dbo.Cart c
	JOIN dbo.Address a ON a.address_id = c.address_id
	WHERE c.cart_id = @cart_id;

	DECLARE @product_available BIT, @business_status VARCHAR(20), @business_zone INT;
	SELECT @product_available = p.is_available, @business_status = b.status, @business_zone = b.zone_id
	FROM dbo.Product p
	JOIN dbo.Business b ON b.business_id = p.business_id
	WHERE p.product_id = @product_id;

	IF @cart_status IS NULL OR @product_available IS NULL
		RETURN -1;
	-- BR-8: only the Active cart of the active address can be edited.
	IF @cart_status <> 'Active' OR @address_active = 0
		RETURN -4;
	-- BR-5: customers only see available products of Active businesses.
	IF @product_available = 0 OR @business_status <> 'Active'
		RETURN -4;
	IF @business_zone <> @address_zone
		RETURN -5;

	DECLARE @current_quantity INT = 0;
	SELECT @current_quantity = quantity FROM dbo.CartItem WHERE cart_id = @cart_id AND product_id = @product_id;

	-- Written as a subtraction so a huge @quantity can't overflow INT.
	IF @quantity > 10 - @current_quantity
		RETURN -6;

	IF @current_quantity = 0
		INSERT INTO dbo.CartItem(cart_id, product_id, quantity, notes, unit_price)
		VALUES (@cart_id, @product_id, @quantity, @notes, NULL);
	ELSE
		UPDATE dbo.CartItem
		SET quantity = quantity + @quantity, notes = ISNULL(@notes, notes)
		WHERE cart_id = @cart_id AND product_id = @product_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Remove_From_Cart(
	@cart_id INT,
	@product_id INT
) AS
	SET NOCOUNT ON;

	IF @cart_id IS NULL OR @product_id IS NULL
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Cart WHERE cart_id = @cart_id)
		RETURN -1;
	IF EXISTS (SELECT 1 FROM dbo.Cart WHERE cart_id = @cart_id AND status <> 'Active')
		RETURN -4;
	IF NOT EXISTS (SELECT 1 FROM dbo.CartItem WHERE cart_id = @cart_id AND product_id = @product_id)
		RETURN -9;

	DELETE FROM dbo.CartItem WHERE cart_id = @cart_id AND product_id = @product_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE FUNCTION dbo.Calculate_Voucher_Discount(
	@voucher_id INT,
	@order_subtotal DECIMAL(10, 2)
) RETURNS DECIMAL(10, 2) AS
BEGIN
	IF @order_subtotal IS NULL OR @order_subtotal < 0
		RETURN -1;

	DECLARE @is_percentage BIT, @amount DECIMAL(10, 2);
	SELECT @is_percentage = is_percentage, @amount = amount
	FROM dbo.Voucher
	WHERE voucher_id = @voucher_id AND status = 'Unused' AND expiry_date >= CAST(GETDATE() AS DATE);

	-- NULL, missing, used or expired voucher: no discount.
	IF @amount IS NULL
		RETURN 0;

	-- BR-13: the discount applies to the subtotal only and never exceeds it.
	DECLARE @discount DECIMAL(10, 2) = CASE WHEN @is_percentage = 1 THEN @order_subtotal * @amount / 100 ELSE @amount END;
	IF @discount > @order_subtotal
		RETURN @order_subtotal;

	RETURN @discount;
END
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Checkout_Cart(
	@cart_id INT,
	@voucher_id INT,
	@payment_method VARCHAR(20),
	@card_id INT
) AS
	SET NOCOUNT ON;

	-- Stored exactly as spelled in Section 2.3, whatever case the caller used.
	SET @payment_method = CASE @payment_method WHEN 'Cash' THEN 'Cash' WHEN 'Card' THEN 'Card' WHEN 'Wallet' THEN 'Wallet' END;

	IF @cart_id IS NULL OR @payment_method IS NULL
		RETURN -1;

	DECLARE @cart_status VARCHAR(20), @customer_id INT, @address_active BIT, @zone_id INT;
	SELECT @cart_status = c.status, @customer_id = c.customer_id, @address_active = a.is_active, @zone_id = a.zone_id
	FROM dbo.Cart c
	JOIN dbo.Address a ON a.address_id = c.address_id
	WHERE c.cart_id = @cart_id;

	IF @cart_status IS NULL
		RETURN -1;
	IF @cart_status <> 'Active'
		RETURN -4;
	IF NOT EXISTS (SELECT 1 FROM dbo.CartItem WHERE cart_id = @cart_id)
		RETURN -9;
	IF EXISTS (SELECT 1 FROM dbo.Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
		RETURN -3;
	-- The order always goes to the active address, so the cart has to be the one of that address.
	IF @address_active = 0
		RETURN -4;

	DECLARE @now DATETIME = GETDATE();
	DECLARE @time TIME = CAST(@now AS TIME);

	IF EXISTS (
		SELECT 1
		FROM dbo.CartItem ci
		JOIN dbo.Product p ON p.product_id = ci.product_id
		JOIN dbo.Business b ON b.business_id = p.business_id
		WHERE ci.cart_id = @cart_id AND (p.is_available = 0 OR b.status <> 'Active')
	)
		RETURN -4;
	IF EXISTS (
		SELECT 1
		FROM dbo.CartItem ci
		JOIN dbo.Product p ON p.product_id = ci.product_id
		JOIN dbo.Business b ON b.business_id = p.business_id
		WHERE ci.cart_id = @cart_id AND b.zone_id <> @zone_id
	)
		RETURN -5;
	-- BR-6: open in [opening_hour, closing_hour), past midnight when opening > closing, all day when equal.
	IF EXISTS (
		SELECT 1
		FROM dbo.CartItem ci
		JOIN dbo.Product p ON p.product_id = ci.product_id
		JOIN dbo.Business b ON b.business_id = p.business_id
		WHERE ci.cart_id = @cart_id
			AND b.opening_hour <> b.closing_hour
			AND NOT (
				(b.opening_hour < b.closing_hour AND @time >= b.opening_hour AND @time < b.closing_hour)
				OR (b.opening_hour > b.closing_hour AND (@time >= b.opening_hour OR @time < b.closing_hour))
			)
	)
		RETURN -4;
	-- BR-13: the voucher must belong to the customer, be Unused and not be expired.
	IF @voucher_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM dbo.Voucher
		WHERE voucher_id = @voucher_id AND customer_id = @customer_id
			AND status = 'Unused' AND expiry_date >= CAST(@now AS DATE)
	)
		RETURN -1;

	-- BR-9: one SubOrder, and so one delivery fee, per business.
	DECLARE @subtotal DECIMAL(10, 2), @business_count INT;
	SELECT @subtotal = SUM(ci.quantity * (p.price - p.discount_amount)), @business_count = COUNT(DISTINCT p.business_id)
	FROM dbo.CartItem ci
	JOIN dbo.Product p ON p.product_id = ci.product_id
	WHERE ci.cart_id = @cart_id;

	DECLARE @delivery_fee DECIMAL(10, 2) = (SELECT delivery_fee FROM dbo.Zone WHERE zone_id = @zone_id);
	DECLARE @discount DECIMAL(10, 2) = dbo.Calculate_Voucher_Discount(@voucher_id, @subtotal);
	DECLARE @total DECIMAL(10, 2) = @subtotal + @business_count * @delivery_fee - @discount;

	-- BR-10: Card needs a valid card of the customer, Wallet needs enough balance, Cash needs nothing.
	IF @payment_method = 'Card' AND NOT EXISTS (
		SELECT 1
		FROM dbo.Card
		WHERE card_id = @card_id AND customer_id = @customer_id AND expiration_date >= CAST(@now AS DATE)
	)
		RETURN -7;
	IF @payment_method = 'Wallet' AND (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = @customer_id) < @total
		RETURN -7;
	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Rider r
		JOIN dbo.Users u ON u.user_id = r.rider_id
		WHERE r.zone_id = @zone_id AND r.is_available = 1 AND u.account_status = 'Active'
	)
		RETURN -8;

	UPDATE ci
	SET unit_price = p.price - p.discount_amount
	FROM dbo.CartItem ci
	JOIN dbo.Product p ON p.product_id = ci.product_id
	WHERE ci.cart_id = @cart_id;

	INSERT INTO dbo.Orders(order_date, status, discount_amount, total_amount, cart_id, zone_id, voucher_id)
	VALUES (@now, 'Placed', @discount, @total, @cart_id, @zone_id, @voucher_id);
	DECLARE @order_id INT = SCOPE_IDENTITY();

	-- ORDER BY fixes the identity order, so SubOrders are numbered in business order.
	INSERT INTO dbo.SubOrder(status, total_price, delivery_fee, order_id, business_id)
	SELECT 'Placed', SUM(ci.quantity * ci.unit_price), @delivery_fee, @order_id, p.business_id
	FROM dbo.CartItem ci
	JOIN dbo.Product p ON p.product_id = ci.product_id
	WHERE ci.cart_id = @cart_id
	GROUP BY p.business_id
	ORDER BY p.business_id;

	-- BR-12: each SubOrder goes to the least-busy available rider of the zone (ties: smallest rider_id).
	-- One SubOrder at a time, so every assignment counts when choosing the rider of the next one.
	DECLARE @rider_id INT;
	DECLARE @suborder_id INT = (SELECT MIN(suborder_id) FROM dbo.SubOrder WHERE order_id = @order_id);
	WHILE @suborder_id IS NOT NULL
	BEGIN
		SELECT TOP 1 @rider_id = r.rider_id
		FROM dbo.Rider r
		JOIN dbo.Users u ON u.user_id = r.rider_id
		WHERE r.zone_id = @zone_id AND r.is_available = 1 AND u.account_status = 'Active'
		ORDER BY (
			SELECT COUNT(*)
			FROM dbo.Delivery d
			JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
			WHERE d.rider_id = r.rider_id AND s.status IN ('Assigned', 'Picked Up')
		), r.rider_id;

		INSERT INTO dbo.Delivery(assigned_at, suborder_id, rider_id)
		VALUES (@now, @suborder_id, @rider_id);
		UPDATE dbo.SubOrder SET status = 'Assigned' WHERE suborder_id = @suborder_id;

		SET @suborder_id = (SELECT MIN(suborder_id) FROM dbo.SubOrder WHERE order_id = @order_id AND suborder_id > @suborder_id);
	END

	UPDATE dbo.Voucher SET status = 'Used' WHERE voucher_id = @voucher_id;

	INSERT INTO dbo.Payment(amount, currency, method, transaction_date, refunded_amount, order_id, card_id)
	VALUES (@total, 'EGP', @payment_method, @now, 0, @order_id, CASE WHEN @payment_method = 'Card' THEN @card_id END);

	IF @payment_method = 'Wallet'
		UPDATE dbo.Customer SET wallet_balance = wallet_balance - @total WHERE customer_id = @customer_id;

	UPDATE dbo.Cart SET status = 'Checked Out' WHERE cart_id = @cart_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Cancel_Order(
	@order_id INT
) AS
	SET NOCOUNT ON;

	IF @order_id IS NULL
		RETURN -1;
	IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE order_id = @order_id)
		RETURN -1;
	IF EXISTS (SELECT 1 FROM dbo.Orders WHERE order_id = @order_id AND status = 'Cancelled')
		RETURN -4;
	IF EXISTS (SELECT 1 FROM dbo.SubOrder WHERE order_id = @order_id AND status IN ('Picked Up', 'Delivered'))
		RETURN -4;

	-- BR-14: cancelling a whole order refunds whatever hasn't been refunded yet, to the wallet unless paid in cash.
	DECLARE @customer_id INT, @method VARCHAR(20), @refund DECIMAL(10, 2);
	SELECT @customer_id = c.customer_id, @method = p.method, @refund = p.amount - p.refunded_amount
	FROM dbo.Orders o
	JOIN dbo.Cart c ON c.cart_id = o.cart_id
	LEFT JOIN dbo.Payment p ON p.order_id = o.order_id
	WHERE o.order_id = @order_id;

	UPDATE dbo.Payment SET refunded_amount = amount WHERE order_id = @order_id;
	IF @method <> 'Cash'
		UPDATE dbo.Customer SET wallet_balance = wallet_balance + @refund WHERE customer_id = @customer_id;

	-- Nothing was picked up, so every SubOrder ends up Cancelled and so does the order (BR-11).
	UPDATE dbo.SubOrder SET status = 'Cancelled' WHERE order_id = @order_id AND status IN ('Placed', 'Assigned');
	UPDATE dbo.Voucher SET status = 'Unused' WHERE voucher_id = (SELECT voucher_id FROM dbo.Orders WHERE order_id = @order_id);
	UPDATE dbo.Orders SET status = 'Cancelled', voucher_id = NULL WHERE order_id = @order_id;

	RETURN 0;
GO

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.Reorder(
	@order_id INT,
	@address_id INT
) AS
	SET NOCOUNT ON;

	IF @order_id IS NULL OR @address_id IS NULL
		RETURN -1;

	DECLARE @customer_id INT, @old_cart_id INT, @order_zone INT;
	SELECT @customer_id = c.customer_id, @old_cart_id = c.cart_id, @order_zone = o.zone_id
	FROM dbo.Orders o
	JOIN dbo.Cart c ON c.cart_id = o.cart_id
	WHERE o.order_id = @order_id;

	DECLARE @address_customer INT, @address_zone INT;
	SELECT @address_customer = customer_id, @address_zone = zone_id
	FROM dbo.Address
	WHERE address_id = @address_id;

	IF @customer_id IS NULL OR @address_customer IS NULL
		RETURN -1;
	IF EXISTS (SELECT 1 FROM dbo.Users WHERE user_id = @customer_id AND account_status = 'Blacklisted')
		RETURN -3;
	IF @address_customer <> @customer_id
		RETURN -3;
	IF @address_zone <> @order_zone
		RETURN -5;
	IF EXISTS (SELECT 1 FROM dbo.Cart WHERE address_id = @address_id AND status = 'Active')
		RETURN -2;
	-- Only products that can still be ordered are copied (BR-5).
	IF NOT EXISTS (
		SELECT 1
		FROM dbo.CartItem ci
		JOIN dbo.Product p ON p.product_id = ci.product_id
		JOIN dbo.Business b ON b.business_id = p.business_id
		WHERE ci.cart_id = @old_cart_id AND p.is_available = 1 AND b.status = 'Active' AND b.zone_id = @address_zone
	)
		RETURN -9;

	-- The chosen address becomes the active one (BR-8).
	UPDATE dbo.Address SET is_active = 0 WHERE customer_id = @customer_id AND address_id <> @address_id;
	UPDATE dbo.Address SET is_active = 1 WHERE address_id = @address_id;

	INSERT INTO dbo.Cart(status, created_at, customer_id, address_id)
	VALUES ('Active', GETDATE(), @customer_id, @address_id);
	DECLARE @new_cart_id INT = SCOPE_IDENTITY();

	INSERT INTO dbo.CartItem(cart_id, product_id, quantity, notes, unit_price)
	SELECT @new_cart_id, ci.product_id, ci.quantity, ci.notes, NULL
	FROM dbo.CartItem ci
	JOIN dbo.Product p ON p.product_id = ci.product_id
	JOIN dbo.Business b ON b.business_id = p.business_id
	WHERE ci.cart_id = @old_cart_id AND p.is_available = 1 AND b.status = 'Active' AND b.zone_id = @address_zone;

	RETURN 0;
GO

-- Farida Tarek (64-29168)
CREATE PROCEDURE dbo.Submit_Feedback
    @suborder_id int,
    @headline varchar(100),
    @description varchar(500),
    @rating int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status varchar(20);

    IF @suborder_id IS NULL
       OR @rating IS NULL OR @rating NOT BETWEEN 1 AND 5
       OR @headline IS NULL OR LTRIM(RTRIM(@headline)) = ''
        RETURN -1;

    SELECT @status = status
    FROM dbo.SubOrder
    WHERE suborder_id = @suborder_id;

    IF @status IS NULL
        RETURN -1;

    IF @status <> 'Delivered'
		RETURN -4;

    IF EXISTS (SELECT 1 FROM dbo.Feedback WHERE suborder_id = @suborder_id)
        RETURN -2;

    INSERT INTO dbo.Feedback (headline, description, rating, suborder_id)
    VALUES (@headline, @description, @rating, @suborder_id);

    RETURN 0;
END;
GO

-- Farida Tarek (64-29168)
CREATE PROCEDURE dbo.Rate_Rider
    @suborder_id int,
    @rider_rating int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status varchar(20);

    IF @suborder_id IS NULL
       OR @rider_rating IS NULL OR @rider_rating NOT BETWEEN 1 AND 5
        RETURN -1;

    SELECT @status = status
    FROM dbo.SubOrder
    WHERE suborder_id = @suborder_id;

    IF @status IS NULL
        RETURN -1;

    IF @status <> 'Delivered'
        RETURN -4;

    IF EXISTS (SELECT 1
               FROM dbo.Delivery
               WHERE suborder_id = @suborder_id
                 AND rider_rating IS NOT NULL)
        RETURN -2;

    UPDATE dbo.Delivery
    SET rider_rating = @rider_rating
    WHERE suborder_id = @suborder_id;

    RETURN 0;
END;
GO

-- Mohand Essam (64-29300)
CREATE FUNCTION dbo.My_Order_History(
	@customer_id INT
) RETURNS TABLE AS RETURN
	SELECT o.order_id,
		o.order_date,
		z.zone_name,
		o.status,
		(SELECT COUNT(*) FROM dbo.SubOrder s WHERE s.order_id = o.order_id) AS number_of_suborders,
		o.discount_amount,
		o.total_amount,
		p.method AS payment_method,
		p.refunded_amount
	FROM dbo.Orders o
	JOIN dbo.Cart c ON c.cart_id = o.cart_id
	JOIN dbo.Zone z ON z.zone_id = o.zone_id
	LEFT JOIN dbo.Payment p ON p.order_id = o.order_id
	WHERE c.customer_id = @customer_id;
GO

-- Retag Atef (64-21789)
CREATE PROCEDURE dbo.Toggle_Favorite
	@customer_id INT,
	@item_id INT,
	@item_type VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;

	IF @customer_id IS NULL OR @item_id IS NULL
		OR @item_type IS NULL OR @item_type NOT IN ('Business', 'Product')
		RETURN -1;

	IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
		RETURN -3;

	IF @item_type = 'Business'
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.Business WHERE business_id = @item_id)
			RETURN -1;

		IF EXISTS (SELECT 1 FROM dbo.Favorite_Business WHERE customer_id = @customer_id AND business_id = @item_id)
			DELETE FROM dbo.Favorite_Business
			WHERE customer_id = @customer_id
				AND business_id = @item_id;
		ELSE
			INSERT INTO dbo.Favorite_Business (customer_id, business_id)
			VALUES (@customer_id, @item_id);
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.Product WHERE product_id = @item_id)
			RETURN -1;

		IF EXISTS (SELECT 1 FROM dbo.Favorite_Product WHERE customer_id = @customer_id AND product_id = @item_id)
			DELETE FROM dbo.Favorite_Product
			WHERE customer_id = @customer_id
				AND product_id = @item_id;
		ELSE
			INSERT INTO dbo.Favorite_Product (customer_id, product_id)
			VALUES (@customer_id, @item_id);
	END

	RETURN 0;
END
GO

-- Retag Atef (64-21789)
CREATE FUNCTION dbo.My_Favorites
(
	@customer_id INT
)
RETURNS TABLE
AS
RETURN
(
	-- Favorite products only. A product can be ordered while it is available and its business is Active (BR-5).
	SELECT p.product_id,
		p.name AS product_name,
		b.name AS business_name,
		CAST(CASE WHEN p.is_available = 1 AND b.status = 'Active' THEN 1 ELSE 0 END AS BIT) AS is_orderable
	FROM dbo.Favorite_Product fp
	INNER JOIN dbo.Product p ON p.product_id = fp.product_id
	INNER JOIN dbo.Business b ON b.business_id = p.business_id
	WHERE fp.customer_id = @customer_id
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.Recommended_Products (@customer_id int)
RETURNS TABLE
AS
RETURN 
(
    SELECT TOP 10
           p.product_id,
           p.name AS product_name,
           b.name AS business_name,
           p.category,
           CAST(p.price - p.discount_amount AS decimal(10,2)) AS final_price
    FROM dbo.Address a
    JOIN dbo.Business b ON b.zone_id = a.zone_id
                       AND b.status = 'Active'
    JOIN dbo.Product p ON p.business_id = b.business_id
                      AND p.is_available = 1
    JOIN (SELECT p2.category, SUM(ci.quantity) AS times_ordered
          FROM dbo.Cart c
          JOIN dbo.Orders o ON o.cart_id = c.cart_id
          JOIN dbo.CartItem ci ON ci.cart_id = c.cart_id
          JOIN dbo.Product p2 ON p2.product_id = ci.product_id
          WHERE c.customer_id = @customer_id
            AND o.status <> 'Cancelled'
          GROUP BY p2.category) oc ON oc.category = p.category
    WHERE a.customer_id = @customer_id
      AND a.is_active = 1
      AND NOT EXISTS (SELECT 1
                      FROM dbo.Cart c3
                      JOIN dbo.Orders o3 ON o3.cart_id = c3.cart_id
                      JOIN dbo.CartItem ci3 ON ci3.cart_id = c3.cart_id
                      WHERE c3.customer_id = @customer_id
                        AND o3.status <> 'Cancelled'
                        AND ci3.product_id = p.product_id)
    ORDER BY oc.times_ordered DESC, p.product_id
);
GO

-- ============================================================================
-- Section 4.7: As a Rider, I should be able to:
-- ============================================================================

-- Farida Tarek (64-29168)
CREATE PROCEDURE dbo.Set_Rider_Availability 
	@rider_id int, @is_available bit
AS
BEGIN
    SET NOCOUNT ON;

    IF @is_available IS NULL OR @rider_id IS NULL
        RETURN -1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Rider WHERE rider_id = @rider_id)
        RETURN -3;

    UPDATE dbo.Rider
    SET is_available = @is_available
    WHERE rider_id = @rider_id;

    RETURN 0;
END;
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.My_Active_Deliveries (@rider_id int)
RETURNS TABLE
AS
RETURN
(
    SELECT
		d.delivery_id,
		o.order_id,
		s.suborder_id,
		b.name AS business_name,
		CAST(u.first_name + ' ' + u.last_name AS varchar(101)) AS customer_name,
		a.description AS address_description,
		z.zone_name,
		s.status,
		d.assigned_at
    FROM dbo.Delivery d
    JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
    JOIN dbo.Orders o ON o.order_id = s.order_id
    JOIN dbo.Business b ON b.business_id = s.business_id
    JOIN dbo.Cart c ON c.cart_id = o.cart_id
    JOIN dbo.Users u ON u.user_id = c.customer_id
    JOIN dbo.Address a ON a.address_id = c.address_id
    JOIN dbo.Zone z ON z.zone_id = o.zone_id
    WHERE d.rider_id = @rider_id
      AND s.status IN ('Assigned', 'Picked Up')
);
GO

-- Farida Tarek (64-29168)
CREATE PROCEDURE dbo.Mark_Picked_Up
    @delivery_id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @suborder_id int, @order_id int, @status varchar(20);
    DECLARE @total int, @cancelled int, @delivered int, @moving int;
    DECLARE @new_status varchar(20);

    IF @delivery_id IS NULL
        RETURN -1;

    SELECT @suborder_id = s.suborder_id,
           @order_id = s.order_id,
           @status = s.status
    FROM dbo.Delivery d
    JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
    WHERE d.delivery_id = @delivery_id;

    IF @suborder_id IS NULL
        RETURN -1;

    IF @status <> 'Assigned'
        RETURN -4;

    UPDATE dbo.SubOrder
    SET status = 'Picked Up'
    WHERE suborder_id = @suborder_id;

    UPDATE dbo.Delivery
    SET picked_up_at = GETDATE()
    WHERE delivery_id = @delivery_id;

    SELECT @total = COUNT(*),
           @cancelled = COUNT(CASE WHEN status = 'Cancelled' THEN 1 END),
           @delivered = COUNT(CASE WHEN status = 'Delivered' THEN 1 END),
           @moving = COUNT(CASE WHEN status IN ('Picked Up', 'Delivered') THEN 1 END)
    FROM dbo.SubOrder
    WHERE order_id = @order_id;

    IF @cancelled = @total
        SET @new_status = 'Cancelled';
    ELSE IF @delivered = @total - @cancelled
        SET @new_status = 'Delivered';
    ELSE IF @moving > 0
        SET @new_status = 'In Progress';
    ELSE
        SET @new_status = 'Placed';

    UPDATE dbo.Orders
    SET status = @new_status
    WHERE order_id = @order_id;

    RETURN 0;
END;
GO

-- Farida Tarek (64-29168)
CREATE PROCEDURE dbo.Mark_Delivered
    @delivery_id int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @suborder_id int, @order_id int, @status varchar(20);
    DECLARE @total int, @cancelled int, @delivered int, @moving int;
    DECLARE @new_status varchar(20);
    DECLARE @now datetime = GETDATE();

    IF @delivery_id IS NULL
        RETURN -1;

    SELECT @suborder_id = s.suborder_id,
           @order_id = s.order_id,
           @status = s.status
    FROM dbo.Delivery d
    JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
    WHERE d.delivery_id = @delivery_id;

    IF @suborder_id IS NULL
        RETURN -1;

    IF @status <> 'Picked Up'
        RETURN -4;

    UPDATE dbo.SubOrder
    SET status = 'Delivered'
    WHERE suborder_id = @suborder_id;

    UPDATE dbo.Delivery
    SET delivered_at = @now,
        tracking_time = DATEDIFF(MINUTE, picked_up_at, @now)
    WHERE delivery_id = @delivery_id;

    SELECT @total = COUNT(*),
           @cancelled = COUNT(CASE WHEN status = 'Cancelled' THEN 1 END),
           @delivered = COUNT(CASE WHEN status = 'Delivered' THEN 1 END),
           @moving = COUNT(CASE WHEN status IN ('Picked Up', 'Delivered') THEN 1 END)
    FROM dbo.SubOrder
    WHERE order_id = @order_id;

    IF @cancelled = @total
        SET @new_status = 'Cancelled';
    ELSE IF @delivered = @total - @cancelled
        SET @new_status = 'Delivered';
    ELSE IF @moving > 0
        SET @new_status = 'In Progress';
    ELSE
        SET @new_status = 'Placed';

    UPDATE dbo.Orders
    SET status = @new_status
    WHERE order_id = @order_id;

    RETURN 0;
END;
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.My_Earnings
(
    @rider_id int,
    @from_date date,
    @to_date date
)
RETURNS TABLE
AS
RETURN
(
    SELECT COUNT(s.suborder_id) AS completed_deliveries,
           CAST(ISNULL(SUM(s.delivery_fee), 0) AS decimal(10,2)) AS total_delivery_fees,
           CAST(ISNULL(SUM(s.delivery_fee), 0) * 0.8 AS decimal(10,2)) AS total_earnings
    FROM dbo.Rider r
    LEFT JOIN dbo.Delivery d
           ON d.rider_id = r.rider_id
          AND CAST(d.delivered_at AS date) BETWEEN @from_date AND @to_date
    LEFT JOIN dbo.SubOrder s
           ON s.suborder_id = d.suborder_id
          AND s.status = 'Delivered'
    WHERE r.rider_id = @rider_id
      AND @from_date <= @to_date
    GROUP BY r.rider_id
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.My_Rating_Summary (@rider_id int)
RETURNS TABLE
AS
RETURN
(
    SELECT CAST(AVG(CAST(d.rider_rating AS decimal(10,2))) AS decimal(10,2)) AS avg_rating,
           COUNT(d.rider_rating) AS ratings_count,
           COUNT(CASE WHEN d.rider_rating = 5 THEN 1 END) AS five_star,
           COUNT(CASE WHEN d.rider_rating = 4 THEN 1 END) AS four_star,
           COUNT(CASE WHEN d.rider_rating = 3 THEN 1 END) AS three_star,
           COUNT(CASE WHEN d.rider_rating = 2 THEN 1 END) AS two_star,
           COUNT(CASE WHEN d.rider_rating = 1 THEN 1 END) AS one_star
    FROM dbo.Rider r
    LEFT JOIN dbo.Delivery d ON d.rider_id = r.rider_id
    WHERE r.rider_id = @rider_id
    GROUP BY r.rider_id
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.My_Delivery_History
(
    @rider_id int,
    @from_date date,
    @to_date date
)
RETURNS TABLE
AS
RETURN
(
    SELECT d.delivery_id,
           s.order_id,
           b.name AS business_name,
           s.status,
           d.assigned_at,
           d.picked_up_at,
           d.delivered_at,
           d.tracking_time
    FROM dbo.Delivery d
    JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
    JOIN dbo.Business b ON b.business_id = s.business_id
    WHERE d.rider_id = @rider_id
      AND s.status IN ('Delivered', 'Cancelled')
      AND CAST(d.assigned_at AS date) BETWEEN @from_date AND @to_date
      AND @from_date <= @to_date
);
GO

-- ============================================================================
-- Section 4.8: System-Level Requirements
-- ============================================================================

-- Retag Atef (64-21789)
CREATE FUNCTION dbo.Search_Platform
(
	@customer_id INT,
	@keyword VARCHAR(100)
)
RETURNS TABLE
AS
RETURN
(
	-- A function may only keep an ORDER BY together with TOP. CHARINDEX instead of LIKE so that
	-- %, _ and [ in the keyword are matched literally.
	SELECT TOP (2147483647)
		b.business_id,
		b.name AS business_name,
		CASE
			WHEN b.name = @keyword THEN 1
			WHEN CHARINDEX(@keyword, b.name) = 1 THEN 2
			ELSE 3
		END AS priority
	FROM dbo.Business b
	INNER JOIN dbo.Address a
		ON a.zone_id = b.zone_id
		AND a.customer_id = @customer_id
		AND a.is_active = 1
	WHERE b.status = 'Active'
		AND CHARINDEX(@keyword, b.name) > 0
	ORDER BY priority, b.business_id
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.Reconcile_Order_Totals ()
RETURNS TABLE
AS
RETURN
(
    SELECT o.order_id,
           CAST(ISNULL(SUM(s.total_price + s.delivery_fee), 0) - o.discount_amount AS decimal(10,2)) AS expected_total,
           o.total_amount AS order_total,
           p.amount AS payment_amount
    FROM dbo.Orders o
    LEFT JOIN dbo.SubOrder s ON s.order_id = o.order_id
    LEFT JOIN dbo.Payment p ON p.order_id = o.order_id
    GROUP BY o.order_id, o.discount_amount, o.total_amount, p.amount
    HAVING o.total_amount <> ISNULL(SUM(s.total_price + s.delivery_fee), 0) - o.discount_amount
        OR p.amount IS NULL
        OR p.amount <> o.total_amount
);
GO

-- Retag Atef (64-21789)
CREATE FUNCTION dbo.Nearby_Businesses_By_Category
(
	@address_id INT,
	@product_category VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
	SELECT TOP (2147483647)
		b.business_id,
		b.name AS business_name,
		z.zone_name,
		CAST(CASE WHEN b.zone_id = a.zone_id THEN 1 ELSE 0 END AS BIT) AS same_zone,
		(
			SELECT CAST(AVG(CAST(d.tracking_time AS DECIMAL(10, 2))) AS DECIMAL(10, 2))
			FROM dbo.Delivery d
			INNER JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id
			INNER JOIN dbo.Orders o ON o.order_id = s.order_id
			WHERE o.zone_id = b.zone_id
				AND s.status = 'Delivered'
		) AS zone_avg_delivery_time
	FROM dbo.Address a
	CROSS JOIN dbo.Business b
	INNER JOIN dbo.Zone z ON z.zone_id = b.zone_id
	WHERE a.address_id = @address_id
		AND b.status = 'Active'
		AND EXISTS (
			SELECT 1
			FROM dbo.Product p
			WHERE p.business_id = b.business_id
				AND p.is_available = 1
				AND p.category = @product_category
		)
	ORDER BY same_zone DESC, zone_avg_delivery_time, b.business_id
);
GO

-- Farida Tarek (64-29168)
CREATE FUNCTION dbo.Platform_Health_Snapshot ()
RETURNS TABLE
AS
RETURN
(
    SELECT
        (SELECT COUNT(*)
         FROM dbo.Business
         WHERE status = 'Active') AS active_businesses,

        (SELECT COUNT(*)
         FROM dbo.Rider
         WHERE is_available = 1) AS available_riders,

        (SELECT COUNT(*)
         FROM dbo.Orders
         WHERE CAST(order_date AS date) = CAST(GETDATE() AS date)) AS orders_today,

        (SELECT CAST(AVG(CAST(tracking_time AS decimal(10,2))) AS decimal(10,2))
         FROM dbo.Delivery
         WHERE CAST(delivered_at AS date) = CAST(GETDATE() AS date)) AS avg_delivery_time_today,

        (SELECT COUNT(*)
         FROM dbo.Feedback
         WHERE rating <= 2
           AND CAST(feedback_date AS date) = CAST(GETDATE() AS date)) AS low_ratings_today
);
GO
