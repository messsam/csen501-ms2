USE master;
GO
DROP DATABASE IF EXISTS LocalDeliveryMarketplace_Team_28;
GO

CREATE DATABASE LocalDeliveryMarketplace_Team_28;
GO
USE LocalDeliveryMarketplace_Team_28;
GO

-- Mohand Essam (64-29300)
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

-- Mohand Essam (64-29300)
CREATE PROCEDURE dbo.dropAllTables AS
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
EXEC dbo.createAllTables;
GO


-- Section 4.2: Basic Data Retrieval (Views)
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

	IF @first_name IS NULL OR LTRIM(RTRIM(@first_name)) = ''
	   OR @last_name IS NULL OR LTRIM(RTRIM(@last_name)) = ''
	   OR @username IS NULL OR LTRIM(RTRIM(@username)) = ''
	   OR @password IS NULL OR LTRIM(RTRIM(@password)) = ''
	   OR @email IS NULL OR LTRIM(RTRIM(@email)) = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
		VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

		DECLARE @new_user_id INT = SCOPE_IDENTITY();

		INSERT INTO dbo.User_Phone (user_id, phone)
		VALUES (@new_user_id, @phone);

		INSERT INTO dbo.Customer (customer_id, wallet_balance)
		VALUES (@new_user_id, 0);

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
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

	IF @first_name IS NULL OR LTRIM(RTRIM(@first_name)) = ''
	   OR @last_name IS NULL OR LTRIM(RTRIM(@last_name)) = ''
	   OR @username IS NULL OR LTRIM(RTRIM(@username)) = ''
	   OR @password IS NULL OR LTRIM(RTRIM(@password)) = ''
	   OR @email IS NULL OR LTRIM(RTRIM(@email)) = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
		VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

		DECLARE @new_user_id INT = SCOPE_IDENTITY();

		INSERT INTO dbo.User_Phone (user_id, phone)
		VALUES (@new_user_id, @phone);

		INSERT INTO dbo.Partner (partner_id)
		VALUES (@new_user_id);

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
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

	IF @first_name IS NULL OR LTRIM(RTRIM(@first_name)) = ''
	   OR @last_name IS NULL OR LTRIM(RTRIM(@last_name)) = ''
	   OR @username IS NULL OR LTRIM(RTRIM(@username)) = ''
	   OR @password IS NULL OR LTRIM(RTRIM(@password)) = ''
	   OR @email IS NULL OR LTRIM(RTRIM(@email)) = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR @vehicle_type IS NULL OR LTRIM(RTRIM(@vehicle_type)) = ''
	   OR @plate_no IS NULL OR LTRIM(RTRIM(@plate_no)) = ''
	   OR @license_no IS NULL OR LTRIM(RTRIM(@license_no)) = ''
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

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
		VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

		DECLARE @new_user_id INT = SCOPE_IDENTITY();

		INSERT INTO dbo.User_Phone (user_id, phone)
		VALUES (@new_user_id, @phone);

		INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id)
		VALUES (@new_user_id, @vehicle_type, @plate_no, @license_no, 1, @zone_id);

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
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
		  AND u.password = @password
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
		  AND u.password = @password
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
		  AND u.password = @password
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
		  AND u.password = @password
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
	   OR @new_password IS NULL OR LTRIM(RTRIM(@new_password)) = ''
	   OR @new_password_repeat IS NULL
	   OR @new_password <> @new_password_repeat
	BEGIN
		RETURN -1;
	END

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Users
		WHERE user_id = @user_id
		  AND password = @old_password
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
-- Section 4.4: What i should be able to do as an Admin
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

	DECLARE @effective_role VARCHAR(20) = ISNULL(@role, 'Super Admin');

	IF @first_name IS NULL OR LTRIM(RTRIM(@first_name)) = ''
	   OR @last_name IS NULL OR LTRIM(RTRIM(@last_name)) = ''
	   OR @username IS NULL OR LTRIM(RTRIM(@username)) = ''
	   OR @password IS NULL OR LTRIM(RTRIM(@password)) = ''
	   OR @email IS NULL OR LTRIM(RTRIM(@email)) = ''
	   OR @phone IS NULL OR LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'
	   OR (@dob IS NOT NULL AND @dob > CAST(GETDATE() AS DATE))
	   OR @effective_role NOT IN ('Super Admin', 'Zone Admin')
	   OR (@effective_role = 'Super Admin' AND @zone_id IS NOT NULL)
	   OR (@effective_role = 'Zone Admin' AND (@zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.Zone WHERE zone_id = @zone_id)))
	BEGIN
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM dbo.Users WHERE username = @username OR email = @email)
	BEGIN
		RETURN -2;
	END

	BEGIN TRY
		BEGIN TRANSACTION;

		INSERT INTO dbo.Users (first_name, middle_name, last_name, username, password, email, dob, account_status)
		VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob, 'Active');

		DECLARE @new_user_id INT = SCOPE_IDENTITY();

		INSERT INTO dbo.User_Phone (user_id, phone)
		VALUES (@new_user_id, @phone);

		INSERT INTO dbo.Admin (admin_id, role, zone_id)
		VALUES (@new_user_id, @effective_role, @zone_id);

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
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
	   OR NOT EXISTS (SELECT 1 FROM dbo.Admin WHERE admin_id = @admin_id AND role = 'Zone Admin')
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
	   OR NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -1;
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

	IF @promo_code IS NULL OR LTRIM(RTRIM(@promo_code)) = ''
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
	   OR @reason IS NULL OR LTRIM(RTRIM(@reason)) = ''
	   OR NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -1;
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

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE dbo.Users
		SET account_status = 'Blacklisted'
		WHERE user_id = @customer_id;

		INSERT INTO dbo.Blacklist (customer_id, admin_id, reason)
		VALUES (@customer_id, @admin_id, @reason);

		DECLARE @CancellableOrders TABLE (
			order_id INT PRIMARY KEY,
			voucher_id INT
		);

		INSERT INTO @CancellableOrders (order_id, voucher_id)
		SELECT o.order_id, o.voucher_id
		FROM dbo.Orders o
		INNER JOIN dbo.Cart c ON c.cart_id = o.cart_id
		WHERE c.customer_id = @customer_id
		  AND o.status <> 'Cancelled'
		  AND NOT EXISTS (
			  SELECT 1
			  FROM dbo.SubOrder s
			  WHERE s.order_id = o.order_id
			    AND s.status IN ('Picked Up', 'Delivered')
		  );

		UPDATE s
		SET s.status = 'Cancelled'
		FROM dbo.SubOrder s
		INNER JOIN @CancellableOrders co ON co.order_id = s.order_id
		WHERE s.status IN ('Placed', 'Assigned');

		UPDATE o
		SET o.status = 'Cancelled',
		    o.voucher_id = NULL
		FROM dbo.Orders o
		INNER JOIN @CancellableOrders co ON co.order_id = o.order_id;

		UPDATE v
		SET v.status = 'Unused'
		FROM dbo.Voucher v
		INNER JOIN @CancellableOrders co ON co.voucher_id = v.voucher_id
		WHERE co.voucher_id IS NOT NULL;

		DECLARE @wallet_refund DECIMAL(10, 2) = 0;
		SELECT @wallet_refund = ISNULL(SUM(p.amount - p.refunded_amount), 0)
		FROM dbo.Payment p
		INNER JOIN @CancellableOrders co ON co.order_id = p.order_id
		WHERE p.method <> 'Cash'
		  AND p.amount > p.refunded_amount;

		UPDATE p
		SET p.refunded_amount = p.amount
		FROM dbo.Payment p
		INNER JOIN @CancellableOrders co ON co.order_id = p.order_id
		WHERE p.amount > p.refunded_amount;

		IF @wallet_refund > 0
		BEGIN
			UPDATE dbo.Customer
			SET wallet_balance = wallet_balance + @wallet_refund
			WHERE customer_id = @customer_id;
		END

		DELETE FROM dbo.Voucher
		WHERE customer_id = @customer_id
		  AND status = 'Unused';

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
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
	   OR NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @customer_id)
	BEGIN
		RETURN -1;
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

	BEGIN TRY
		BEGIN TRANSACTION;

		DELETE FROM dbo.Blacklist
		WHERE customer_id = @customer_id;

		UPDATE dbo.Users
		SET account_status = 'Active'
		WHERE user_id = @customer_id;

		COMMIT TRANSACTION;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN -1;
	END CATCH
END
GO