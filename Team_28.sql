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