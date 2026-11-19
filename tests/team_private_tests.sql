/* =====================================================================================
   TEAM 28 PRIVATE TESTS
   Our own edge cases on top of the course's tests/public_tests.sql: the kind of cases the
   TAs' private tests may use. Every scenario starts again from the course seed data.

   HOW TO RUN: run Team_28.sql, then this file:
       sqlcmd -S "(localdb)\MSSQLLocalDB" -i tests\team_private_tests.sql
   Only failed checks are printed, then "Passed N of M checks."

   WARNING: like the public tests, this deletes every row of LocalDeliveryMarketplace_Team_28.
   The last section tests 4.1 by dropping the tables and every procedure, function and view,
   so run Team_28.sql again afterwards.

   Checks marked (our choice) pin down return codes the spec leaves open (see AGENTS.md).
   ===================================================================================== */
USE LocalDeliveryMarketplace_Team_28;
GO
SET NOCOUNT ON;
GO
IF OBJECT_ID('tempdb..#R') IS NOT NULL DROP TABLE #R;
IF OBJECT_ID('tempdb..#Last') IS NOT NULL DROP TABLE #Last;
CREATE TABLE #R (ok BIT, msg NVARCHAR(MAX));
CREATE TABLE #Last (rc INT, ok BIT);
GO
/* ------------------------------ Harness (temporary procedures only) ------------------------------ */
CREATE PROCEDURE #SeedData AS
BEGIN
SET NOCOUNT ON;
    /* ---------------- Zones ---------------- */
    SET IDENTITY_INSERT dbo.Zone ON;
    INSERT INTO dbo.Zone (zone_id, zone_name, delivery_fee) VALUES
        (1, 'Maadi', 20.00),
        (2, 'Zamalek', 25.00),
        (3, 'New Cairo', 30.00),
        (4, 'Heliopolis', 15.00);
    SET IDENTITY_INSERT dbo.Zone OFF;

    /* ---------------- Users: 1-3 admins, 4-11 and 24 partners, 12-16 riders, 17-23 customers ---------------- */
    SET IDENTITY_INSERT dbo.Users ON;
    INSERT INTO dbo.Users (user_id, first_name, middle_name, last_name, username, password, email, dob, account_status) VALUES
        (1,  'Mona',    'Adel',   'Hassan',  'mona.hassan',   'Pass@001', 'mona.hassan@mail.com',   '1985-03-12', 'Active'),
        (2,  'Karim',   NULL,     'Adel',    'karim.adel',    'Pass@002', 'karim.adel@mail.com',    '1990-07-01', 'Active'),
        (3,  'Hana',    NULL,     'Samir',   'hana.samir',    'Pass@003', 'hana.samir@mail.com',    '1992-11-23', 'Active'),
        (4,  'Tarek',   'Ali',    'Fouad',   'tarek.fouad',   'Pass@004', 'tarek.fouad@mail.com',   '1980-01-15', 'Active'),
        (5,  'Laura',   NULL,     'Bianchi', 'laura.bianchi', 'Pass@005', 'laura.bianchi@mail.com', '1983-04-30', 'Active'),
        (6,  'Seif',    NULL,     'Mahmoud', 'seif.mahmoud',  'Pass@006', 'seif.mahmoud@mail.com',  '1979-09-09', 'Active'),
        (7,  'Kenji',   NULL,     'Sato',    'kenji.sato',    'Pass@007', 'kenji.sato@mail.com',    '1987-02-14', 'Active'),
        (8,  'Dina',    NULL,     'Fathy',   'dina.fathy',    'Pass@008', 'dina.fathy@mail.com',    '1991-06-18', 'Active'),
        (9,  'Rania',   NULL,     'Ezz',     'rania.ezz',     'Pass@009', 'rania.ezz@mail.com',     '1984-12-02', 'Active'),
        (10, 'Hassan',  NULL,     'Gaber',   'hassan.gaber',  'Pass@010', 'hassan.gaber@mail.com',  '1978-08-25', 'Active'),
        (11, 'Mai',     NULL,     'Lotfy',   'mai.lotfy',     'Pass@011', 'mai.lotfy@mail.com',     '1995-03-03', 'Active'),
        (12, 'Ali',     NULL,     'Ibrahim', 'ali.ibrahim',   'Pass@012', 'ali.ibrahim@mail.com',   '1998-05-05', 'Active'),
        (13, 'Mostafa', NULL,     'Kamal',   'mostafa.kamal', 'Pass@013', 'mostafa.kamal@mail.com', '1997-10-10', 'Active'),
        (14, 'Yehia',   NULL,     'Saad',    'yehia.saad',    'Pass@014', 'yehia.saad@mail.com',    '1999-01-20', 'Active'),
        (15, 'Ziad',    NULL,     'Nabil',   'ziad.nabil',    'Pass@015', 'ziad.nabil@mail.com',    '1996-04-04', 'Active'),
        (16, 'Fady',    NULL,     'Ramzy',   'fady.ramzy',    'Pass@016', 'fady.ramzy@mail.com',    '1994-07-07', 'Active'),
        (17, 'Ahmed',   'Samy',   'Salem',   'ahmed.salem',   'Pass@017', 'ahmed.salem@mail.com',   '2000-02-02', 'Active'),
        (18, 'Sara',    NULL,     'Mostafa', 'sara.mostafa',  'Pass@018', 'sara.mostafa@mail.com',  '2001-08-08', 'Active'),
        (19, 'Omar',    NULL,     'Khaled',  'omar.khaled',   'Pass@019', 'omar.khaled@mail.com',   '1999-09-19', 'Active'),
        (20, 'Laila',   NULL,     'Hany',    'laila.hany',    'Pass@020', 'laila.hany@mail.com',    '2002-12-12', 'Active'),
        (21, 'Youssef', NULL,     'Amin',    'youssef.amin',  'Pass@021', 'youssef.amin@mail.com',  '1993-03-21', 'Blacklisted'),
        (22, 'Nour',    NULL,     'Tamer',   'nour.tamer',    'Pass@022', 'nour.tamer@mail.com',    '2003-06-22', 'Active'),
        (23, 'Farida',  NULL,     'Naguib',  'farida.naguib', 'Pass@023', 'farida.naguib@mail.com', '2000-10-10', 'Active'),
        (24, 'Nabil',   NULL,     'Fares',   'nabil.fares',   'Pass@024', 'nabil.fares@mail.com',   '1986-05-17', 'Active');
    SET IDENTITY_INSERT dbo.Users OFF;

    INSERT INTO dbo.User_Phone (user_id, phone) VALUES
        (1, '01000000001'), (2, '01000000002'), (3, '01000000003'), (4, '01000000004'),
        (5, '01000000005'), (6, '01000000006'), (7, '01000000007'), (8, '01000000008'),
        (9, '01000000009'), (10, '01000000010'), (11, '01000000011'), (12, '01000000012'),
        (13, '01000000013'), (14, '01000000014'), (15, '01000000015'), (16, '01000000016'),
        (17, '01000000017'), (17, '01100000017'), (18, '01000000018'), (19, '01000000019'),
        (20, '01000000020'), (21, '01000000021'), (22, '01000000022'), (23, '01000000023'),
        (24, '01000000024');

    INSERT INTO dbo.Admin (admin_id, role, zone_id) VALUES
        (1, 'Super Admin', NULL),
        (2, 'Zone Admin', 1),
        (3, 'Zone Admin', 2);

    INSERT INTO dbo.Partner (partner_id) VALUES (4), (5), (6), (7), (8), (9), (10), (11), (24);

    INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id) VALUES
        (12, 'Motorcycle', 'MAA-1201', 'LIC-1201', 1, 1),
        (13, 'Motorcycle', 'MAA-1302', 'LIC-1302', 1, 1),
        (14, 'Bicycle',    'MAA-1403', 'LIC-1403', 0, 1),
        (15, 'Motorcycle', 'ZAM-1504', 'LIC-1504', 1, 2),
        (16, 'Car',        'NCA-1605', 'LIC-1605', 1, 3);

    INSERT INTO dbo.Customer (customer_id, wallet_balance) VALUES
        (17, 500.00),
        (18, 50.00),
        (19, 0.00),
        (20, 100.00),
        (21, 0.00),
        (22, 25.00),
        (23, 0.00);

    /* ---------------- Addresses (exactly one active address per customer) and cards ---------------- */
    SET IDENTITY_INSERT dbo.Address ON;
    INSERT INTO dbo.Address (address_id, description, is_active, customer_id, zone_id) VALUES
        (1,  'Street 9 Building 12',   1, 17, 1),
        (2,  'Zamalek Tower Apt 3',    0, 17, 2),
        (3,  'Dokki Old Flat',         0, 17, 2),
        (4,  'Road 233 Villa 7',       1, 18, 1),
        (5,  'Zamalek Tower Apt 3',    1, 19, 2),
        (6,  'Fifth Settlement B5',    1, 20, 3),
        (7,  'Degla Street 4',         1, 21, 1),
        (8,  'Road 233 Villa 7',       1, 22, 1),
        (9,  'Old Heliopolis Flat',    0, 20, 4),
        (10, 'Maadi Corniche 5',       0, 17, 1),
        (11, 'Sarayat Street 8',       1, 23, 1),
        (12, 'Fifth Settlement B9',    0, 20, 3);
    SET IDENTITY_INSERT dbo.Address OFF;

    SET IDENTITY_INSERT dbo.Card ON;
    INSERT INTO dbo.Card (card_id, card_no, card_holder_name, expiration_date, customer_id) VALUES
        (1, '4111111111111111', 'Ahmed Salem',  '2030-12-31', 17),
        (2, '5500000000000004', 'Ahmed Salem',  '2025-06-30', 17),
        (3, '4000000000000002', 'Omar Khaled',  '2029-01-31', 19),
        (4, '4012888888881881', 'Laila Hany',   '2028-05-31', 20),
        (5, '4222222222222222', 'Sara Mostafa', '2031-01-31', 18);
    SET IDENTITY_INSERT dbo.Card OFF;

    /* ---------------- Businesses ---------------- */
    SET IDENTITY_INSERT dbo.Business ON;
    INSERT INTO dbo.Business (business_id, name, description, link_website, opening_hour, closing_hour,
                              expected_delivery_time, status, suspension_reason, partner_id, zone_id) VALUES
        (1, 'Koshary El Tahrir', 'Traditional Egyptian koshary', 'www.koshary.example', '00:00', '00:00', 30, 'Active',    NULL,                4,  1),
        (2, 'Pizza Roma',        'Wood-fired Italian pizza',     NULL,                  '00:00', '00:00', 40, 'Active',    NULL,                5,  1),
        (3, 'Seif Pharmacy',     'Medicines and personal care',  'www.seif.example',    '00:00', '00:00', 25, 'Active',    NULL,                6,  1),
        (4, 'Sushi Zen',         'Japanese sushi bar',           NULL,                  '00:00', '00:00', 45, 'Active',    NULL,                7,  2),
        (5, 'Zamalek Pharmacy',  'Neighborhood pharmacy',        NULL,                  '09:00', '21:00', 20, 'Pending',   NULL,                8,  2),
        (6, 'Sweet Corner',      'Oriental desserts',            NULL,                  '10:00', '02:00', 35, 'Suspended', 'Hygiene violation', 9,  3),
        (7, 'Cairo Grill',       'Charcoal grilled meats',       NULL,                  '00:00', '00:00', 50, 'Active',    NULL,                10, 3),
        (8, 'Nile Sweets',       'Konafa and oriental sweets',   NULL,                  '10:00', '23:00', 30, 'Rejected',  NULL,                24, 3);
    SET IDENTITY_INSERT dbo.Business OFF;

    INSERT INTO dbo.Business_Phone (business_id, phone) VALUES
        (1, '02200000001'), (1, '02200000011'), (2, '02200000002'), (3, '02200000003'),
        (4, '02200000004'), (5, '02200000005'), (6, '02200000006'), (7, '02200000007'),
        (8, '02200000008');

    INSERT INTO dbo.Restaurant (business_id, cuisine_type, food_category) VALUES
        (1, 'Egyptian',  'Fast Food'),
        (2, 'Italian',   'Pizza'),
        (4, 'Japanese',  'Seafood'),
        (6, 'Egyptian',  'Desserts'),
        (7, 'Egyptian',  'Grills'),
        (8, 'Egyptian',  'Desserts');

    INSERT INTO dbo.Pharmacy (business_id, pharmacy_type) VALUES
        (3, 'Retail'),
        (5, 'Retail');

    /* ---------------- Blacklist: customer 21 was blacklisted by Zone Admin 2 ---------------- */
    INSERT INTO dbo.Blacklist (customer_id, admin_id, reason) VALUES
        (21, 2, 'Repeated payment disputes');

    /* ---------------- Products ---------------- */
    SET IDENTITY_INSERT dbo.Product ON;
    INSERT INTO dbo.Product (product_id, name, description, category, price, discount_amount, is_available, business_id) VALUES
        (1,  'Koshary Large',       'Large koshary box',        'Main Dishes', 60.00,  0.00,  1, 1),
        (2,  'Koshary Small',       'Small koshary box',        'Main Dishes', 40.00,  0.00,  1, 1),
        (3,  'Rice Pudding',        'Creamy rice pudding',      'Desserts',    25.00,  5.00,  1, 1),
        (4,  'Feteer',              'Egyptian pastry',          'Main Dishes', 80.00,  0.00,  0, 1),
        (5,  'Margherita Pizza',    'Tomato and mozzarella',    'Pizza',       120.00, 20.00, 1, 2),
        (6,  'Pepperoni Pizza',     'Spicy pepperoni',          'Pizza',       150.00, 0.00,  1, 2),
        (7,  'Tiramisu',            'Italian dessert',          'Desserts',    70.00,  0.00,  1, 2),
        (8,  'Panadol Extra',       'Pain relief, 24 tablets',  'Painkillers', 45.00,  0.00,  1, 3),
        (9,  'Vitamin C',           '1000 mg, 30 tablets',      'Vitamins',    90.00,  10.00, 1, 3),
        (10, 'Hand Sanitizer',      '250 ml',                   'Hygiene',     30.00,  0.00,  1, 3),
        (11, 'Salmon Roll',         '8 pieces',                 'Sushi',       180.00, 0.00,  1, 4),
        (12, 'Miso Soup',           'Hot soup',                 'Soups',       50.00,  0.00,  1, 4),
        (13, 'Green Tea Ice Cream', '2 scoops',                 'Desserts',    60.00,  0.00,  1, 4),
        (14, 'Aspirin',             '100 mg, 20 tablets',       'Painkillers', 20.00,  0.00,  1, 5),
        (15, 'Basbousa',            'Semolina cake',            'Desserts',    35.00,  0.00,  0, 6),
        (16, 'Mixed Grill',         'Kofta, kebab and chicken', 'Grill',       220.00, 0.00,  1, 7),
        (17, 'Kofta Sandwich',      'Grilled kofta',            'Sandwiches',  55.00,  0.00,  1, 7),
        (18, 'Hawawshi',            'Spiced meat bread',        'Main Dishes', 50.00,  0.00,  1, 1),
        (19, 'Face Mask',           'Box of 10',                'Hygiene',     15.00,  0.00,  1, 3),
        (20, 'Konafa',              'Cheese konafa',            'Desserts',    40.00,  0.00,  1, 8);
    SET IDENTITY_INSERT dbo.Product OFF;

    INSERT INTO dbo.Favorite_Business (customer_id, business_id) VALUES (17, 1), (18, 6);
    INSERT INTO dbo.Favorite_Product (customer_id, product_id) VALUES (17, 5), (19, 15);

    /* ---------------- Vouchers (Unused or Used; vouchers of a blacklisted customer are deleted) ---------------- */
    SET IDENTITY_INSERT dbo.Voucher ON;
    INSERT INTO dbo.Voucher (voucher_id, promo_code, is_percentage, amount, expiry_date, status, customer_id) VALUES
        (1, 'SARA30',    0, 30.00, '2027-06-30', 'Used',    18),
        (2, 'OMAR10',    1, 10.00, '2027-06-30', 'Used',    19),
        (3, 'WELCOME50', 0, 50.00, '2030-12-31', 'Unused',  17),
        (4, 'SAVE10',    1, 10.00, '2030-12-31', 'Unused',  17),
        (5, 'NOUR15',    0, 15.00, '2030-12-31', 'Used',    22),
        (6, 'OLD20',     0, 20.00, '2025-01-01', 'Unused',  20),
        (7, 'SARA25',    1, 25.00, '2030-12-31', 'Unused',  18);
    SET IDENTITY_INSERT dbo.Voucher OFF;

    /* ---------------- Carts: 1-8 checked out (orders 1-8), 9-15 active (at most one per address) ---------------- */
    SET IDENTITY_INSERT dbo.Cart ON;
    INSERT INTO dbo.Cart (cart_id, status, created_at, customer_id, address_id) VALUES
        (1,  'Checked Out', '2026-09-01 11:50', 17, 1),
        (2,  'Checked Out', '2026-09-02 18:50', 18, 4),
        (3,  'Checked Out', '2026-09-05 12:50', 19, 5),
        (4,  'Checked Out', '2026-09-10 19:50', 21, 7),
        (5,  'Checked Out', '2026-09-15 13:50', 20, 6),
        (6,  'Checked Out', '2026-09-20 17:50', 17, 1),
        (7,  'Checked Out', '2026-09-21 09:50', 18, 4),
        (8,  'Checked Out', '2026-09-21 10:50', 22, 8),
        (9,  'Active',      '2026-09-25 10:00', 17, 1),
        (10, 'Active',      '2026-09-25 10:00', 18, 4),
        (11, 'Active',      '2026-09-25 10:00', 19, 5),
        (12, 'Active',      '2026-09-25 10:00', 21, 7),
        (13, 'Active',      '2026-09-25 10:00', 20, 6),
        (14, 'Active',      '2026-09-25 10:00', 22, 8),
        (15, 'Active',      '2026-09-25 10:00', 17, 3);
    SET IDENTITY_INSERT dbo.Cart OFF;

    INSERT INTO dbo.CartItem (cart_id, product_id, quantity, notes, unit_price) VALUES
        (1, 1, 2, 'Extra sauce', 60.00),
        (1, 5, 1, NULL,          100.00),
        (2, 8, 2, NULL,          45.00),
        (2, 3, 2, NULL,          20.00),
        (3, 11, 1, NULL,         180.00),
        (3, 12, 2, 'No onions',  50.00),
        (4, 7, 1, NULL,          70.00),
        (5, 16, 1, NULL,         220.00),
        (5, 15, 2, NULL,         35.00),
        (6, 2, 3, NULL,          40.00),
        (6, 10, 1, NULL,         30.00),
        (7, 9, 1, NULL,          80.00),
        (8, 6, 1, NULL,          150.00),
        (9, 1, 1, 'Extra sauce', NULL),
        (9, 8, 2, NULL,          NULL),
        (11, 12, 1, NULL,        NULL),
        (12, 1, 1, NULL,         NULL),
        (13, 17, 2, NULL,        NULL),
        (14, 4, 1, NULL,         NULL),
        (15, 11, 1, NULL,        NULL);

    /* ---------------- Orders, suborders, deliveries, payments, feedback ---------------- */
    SET IDENTITY_INSERT dbo.Orders ON;
    INSERT INTO dbo.Orders (order_id, order_date, status, discount_amount, total_amount, cart_id, zone_id, voucher_id) VALUES
        (1, '2026-09-01 12:00', 'Delivered',   0.00,  260.00, 1, 1, NULL),
        (2, '2026-09-02 19:00', 'Delivered',   30.00, 140.00, 2, 1, 1),
        (3, '2026-09-05 13:00', 'Delivered',   28.00, 277.00, 3, 2, 2),
        (4, '2026-09-10 20:00', 'Cancelled',   0.00,  90.00,  4, 1, NULL),
        (5, '2026-09-15 14:00', 'Delivered',   0.00,  350.00, 5, 3, NULL),
        (6, '2026-09-20 18:00', 'In Progress', 0.00,  190.00, 6, 1, NULL),
        (7, '2026-09-21 10:00', 'Placed',      0.00,  100.00, 7, 1, NULL),
        (8, '2026-09-21 11:00', 'Placed',      15.00, 155.00, 8, 1, 5);
    SET IDENTITY_INSERT dbo.Orders OFF;

    SET IDENTITY_INSERT dbo.SubOrder ON;
    INSERT INTO dbo.SubOrder (suborder_id, status, total_price, delivery_fee, order_id, business_id) VALUES
        (1,  'Delivered', 120.00, 20.00, 1, 1),
        (2,  'Delivered', 100.00, 20.00, 1, 2),
        (3,  'Delivered', 90.00,  20.00, 2, 3),
        (4,  'Delivered', 40.00,  20.00, 2, 1),
        (5,  'Delivered', 280.00, 25.00, 3, 4),
        (6,  'Cancelled', 70.00,  20.00, 4, 2),
        (7,  'Delivered', 220.00, 30.00, 5, 7),
        (8,  'Cancelled', 70.00,  30.00, 5, 6),
        (9,  'Picked Up', 120.00, 20.00, 6, 1),
        (10, 'Assigned',  30.00,  20.00, 6, 3),
        (11, 'Assigned',  80.00,  20.00, 7, 3),
        (12, 'Assigned',  150.00, 20.00, 8, 2);
    SET IDENTITY_INSERT dbo.SubOrder OFF;

    SET IDENTITY_INSERT dbo.Delivery ON;
    INSERT INTO dbo.Delivery (delivery_id, assigned_at, picked_up_at, delivered_at, tracking_time, rider_rating, suborder_id, rider_id) VALUES
        (1,  '2026-09-01 12:00', '2026-09-01 12:10', '2026-09-01 12:40', 30,   5,    1,  12),
        (2,  '2026-09-01 12:00', '2026-09-01 12:15', '2026-09-01 12:35', 20,   4,    2,  13),
        (3,  '2026-09-02 19:00', '2026-09-02 19:05', '2026-09-02 19:30', 25,   4,    3,  12),
        (4,  '2026-09-02 19:00', '2026-09-02 19:10', '2026-09-02 19:25', 15,   NULL, 4,  13),
        (5,  '2026-09-05 13:00', '2026-09-05 13:10', '2026-09-05 13:45', 35,   5,    5,  15),
        (6,  '2026-09-10 20:00', NULL,               NULL,               NULL, NULL, 6,  12),
        (7,  '2026-09-15 14:00', '2026-09-15 14:20', '2026-09-15 15:00', 40,   3,    7,  16),
        (8,  '2026-09-15 14:00', NULL,               NULL,               NULL, NULL, 8,  16),
        (9,  '2026-09-20 18:00', '2026-09-20 18:20', NULL,               NULL, NULL, 9,  12),
        (10, '2026-09-20 18:00', NULL,               NULL,               NULL, NULL, 10, 13),
        (11, '2026-09-21 10:00', NULL,               NULL,               NULL, NULL, 11, 12),
        (12, '2026-09-21 11:00', NULL,               NULL,               NULL, NULL, 12, 13);
    SET IDENTITY_INSERT dbo.Delivery OFF;

    SET IDENTITY_INSERT dbo.Payment ON;
    INSERT INTO dbo.Payment (payment_id, amount, currency, method, transaction_date, refunded_amount, order_id, card_id) VALUES
        (1, 260.00, 'EGP', 'Card',   '2026-09-01 12:00', 0.00,   1, 1),
        (2, 140.00, 'EGP', 'Wallet', '2026-09-02 19:00', 0.00,   2, NULL),
        (3, 277.00, 'EGP', 'Card',   '2026-09-05 13:00', 0.00,   3, 3),
        (4, 90.00,  'EGP', 'Cash',   '2026-09-10 20:00', 90.00,  4, NULL),
        (5, 350.00, 'EGP', 'Card',   '2026-09-15 14:00', 100.00, 5, 4),
        (6, 190.00, 'EGP', 'Card',   '2026-09-20 18:00', 0.00,   6, 1),
        (7, 100.00, 'EGP', 'Cash',   '2026-09-21 10:00', 0.00,   7, NULL),
        (8, 155.00, 'EGP', 'Wallet', '2026-09-21 11:00', 0.00,   8, NULL);
    SET IDENTITY_INSERT dbo.Payment OFF;

    SET IDENTITY_INSERT dbo.Feedback ON;
    INSERT INTO dbo.Feedback (feedback_id, headline, description, rating, feedback_date, suborder_id) VALUES
        (1, 'Great koshary',   'Hot and tasty',              5, '2026-09-01 13:00', 1),
        (2, 'Fast delivery',   'Medicine arrived quickly',   4, '2026-09-02 20:00', 3),
        (3, 'Too sweet',       'Rice pudding was too sweet', 2, '2026-09-02 20:05', 4),
        (4, 'Excellent sushi', 'Fresh fish',                 5, '2026-09-05 14:30', 5),
        (5, 'Good grill',      'Generous portions',          4, '2026-09-15 16:00', 7);
    SET IDENTITY_INSERT dbo.Feedback OFF;
END
GO
/* Deletes every row, restarts the identities and reloads the seed data (does not rely on clearAllTables). */
CREATE PROCEDURE #Reset AS
BEGIN
	SET NOCOUNT ON;
	IF @@TRANCOUNT > 0 ROLLBACK;
	DELETE FROM dbo.Feedback; DELETE FROM dbo.Payment; DELETE FROM dbo.Delivery; DELETE FROM dbo.SubOrder;
	DELETE FROM dbo.Orders; DELETE FROM dbo.CartItem; DELETE FROM dbo.Cart; DELETE FROM dbo.Voucher;
	DELETE FROM dbo.Favorite_Product; DELETE FROM dbo.Favorite_Business; DELETE FROM dbo.Product;
	DELETE FROM dbo.Blacklist; DELETE FROM dbo.Pharmacy; DELETE FROM dbo.Restaurant; DELETE FROM dbo.Business_Phone;
	DELETE FROM dbo.Business; DELETE FROM dbo.Card; DELETE FROM dbo.Address; DELETE FROM dbo.Customer;
	DELETE FROM dbo.Rider; DELETE FROM dbo.Partner; DELETE FROM dbo.Admin; DELETE FROM dbo.User_Phone;
	DELETE FROM dbo.Users; DELETE FROM dbo.Zone;
	DECLARE @sql NVARCHAR(MAX) = N'';
	SELECT @sql = @sql + N'DBCC CHECKIDENT (''dbo.' + t.name + N''', RESEED, 0) WITH NO_INFOMSGS; '
	FROM sys.identity_columns ic
	JOIN sys.tables t ON t.object_id = ic.object_id
	WHERE ic.last_value IS NOT NULL AND t.schema_id = SCHEMA_ID('dbo');
	EXEC sp_executesql @sql;
	EXEC #SeedData;
END
GO
/* Row count and checksum of every table, to prove that a rejected call changed nothing. */
CREATE PROCEDURE #State @s NVARCHAR(MAX) OUTPUT AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql NVARCHAR(MAX) = N'SELECT @s = CONCAT(N'''', N''tables:''';
	SELECT @sql = @sql + N', N''' + name + N':'', (SELECT CONCAT(COUNT_BIG(*), N''/'', CHECKSUM_AGG(BINARY_CHECKSUM(*))) FROM dbo.'
		+ QUOTENAME(name) + N'), N'';'''
	FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name;
	SET @sql = @sql + N')';
	EXEC sp_executesql @sql, N'@s NVARCHAR(MAX) OUTPUT', @s OUTPUT;
END
GO
CREATE PROCEDURE #Log @ok BIT, @msg NVARCHAR(MAX) AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO #R VALUES (@ok, @msg);
	IF @ok = 0 PRINT N'FAIL ' + @msg;
END
GO
/* Calls a procedure (@call = name and arguments, an OUTPUT bit may be passed as @ok) and checks its return code.
   A negative expected code must also leave every table unchanged. The code and @ok are kept in #Last. */
CREATE PROCEDURE #T @label NVARCHAR(300), @call NVARCHAR(MAX), @expected INT AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @before NVARCHAR(MAX), @after NVARCHAR(MAX), @rc INT, @ok BIT, @err NVARCHAR(4000), @pass BIT, @msg NVARCHAR(MAX);
	DECLARE @q NVARCHAR(MAX) = N'EXEC @rc = ' + @call;
	EXEC #State @before OUTPUT;
	BEGIN TRY
		EXEC sp_executesql @q, N'@rc INT OUTPUT, @ok BIT OUTPUT', @rc OUTPUT, @ok OUTPUT;
	END TRY
	BEGIN CATCH
		SET @err = ERROR_MESSAGE();
	END CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK;
		SET @err = CONCAT(@err, N' [left a transaction open]');
	END
	EXEC #State @after OUTPUT;
	DELETE FROM #Last;
	INSERT INTO #Last VALUES (@rc, @ok);
	SET @pass = CASE WHEN @err IS NULL AND @rc = @expected AND (@expected = 0 OR @before = @after) THEN 1 ELSE 0 END;
	SET @msg = CONCAT(@label, N': expected ', @expected, N', got ', ISNULL(CAST(@rc AS NVARCHAR(10)), N'NULL'),
		CASE WHEN @expected <> 0 AND @before <> @after THEN N' [the rejected call changed the database]' ELSE N'' END,
		CASE WHEN @err IS NOT NULL THEN N' [error: ' + @err + N']' ELSE N'' END, N'  {', @call, N'}');
	EXEC #Log @pass, @msg;
END
GO
/* Compares the single value returned by @query (as text) with @expected. NULL is shown as <NULL>. */
CREATE PROCEDURE #V @label NVARCHAR(300), @query NVARCHAR(MAX), @expected NVARCHAR(4000) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @got NVARCHAR(4000), @pass BIT, @msg NVARCHAR(MAX), @q NVARCHAR(MAX) = N'SELECT @v = CONVERT(NVARCHAR(4000), (' + @query + N'))';
	BEGIN TRY
		EXEC sp_executesql @q, N'@v NVARCHAR(4000) OUTPUT', @got OUTPUT;
		SET @got = ISNULL(@got, N'<NULL>');
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK;
		SET @got = N'ERROR: ' + ERROR_MESSAGE();
	END CATCH
	SET @pass = CASE WHEN @got = ISNULL(@expected, N'<NULL>') THEN 1 ELSE 0 END;
	SET @msg = CONCAT(@label, N': expected ', ISNULL(@expected, N'<NULL>'), N', got ', @got);
	EXEC #Log @pass, @msg;
END
GO
/* Runs a raw statement that the table constraints must reject, leaving every table unchanged. */
CREATE PROCEDURE #Rej @label NVARCHAR(300), @sql NVARCHAR(MAX) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @before NVARCHAR(MAX), @after NVARCHAR(MAX), @failed BIT = 0, @pass BIT, @msg NVARCHAR(MAX);
	EXEC #State @before OUTPUT;
	BEGIN TRY
		EXEC sp_executesql @sql;
	END TRY
	BEGIN CATCH
		SET @failed = 1;
	END CATCH
	IF @@TRANCOUNT > 0 ROLLBACK;
	EXEC #State @after OUTPUT;
	SET @pass = CASE WHEN @failed = 1 AND @before = @after THEN 1 ELSE 0 END;
	SET @msg = CONCAT(@label, CASE WHEN @failed = 0 THEN N': the statement was accepted' ELSE N'' END,
		CASE WHEN @before <> @after THEN N' [changed the database]' ELSE N'' END);
	EXEC #Log @pass, @msg;
END
GO
/* Runs setup statements that must succeed. */
CREATE PROCEDURE #Exec @label NVARCHAR(300), @sql NVARCHAR(MAX) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @err NVARCHAR(4000), @pass BIT, @msg NVARCHAR(MAX);
	BEGIN TRY
		EXEC sp_executesql @sql;
	END TRY
	BEGIN CATCH
		SET @err = ERROR_MESSAGE();
	END CATCH
	IF @@TRANCOUNT > 0 ROLLBACK;
	SET @pass = CASE WHEN @err IS NULL THEN 1 ELSE 0 END;
	SET @msg = CONCAT(@label, N': ', @err);
	EXEC #Log @pass, @msg;
END
GO

/* =============================== 4.1 Tables: constraints and defaults =============================== */
EXEC #Reset;
EXEC #Rej '4.1.b zone_name is UNIQUE', N'INSERT INTO dbo.Zone (zone_name, delivery_fee) VALUES (''Maadi'', 5)';
EXEC #Rej '4.1.b delivery_fee >= 0', N'INSERT INTO dbo.Zone (zone_name, delivery_fee) VALUES (''Dokki'', -1)';
EXEC #Rej '4.1.b username is UNIQUE', N'INSERT INTO dbo.Users (first_name, last_name, username, password, email) VALUES (''A'', ''B'', ''ahmed.salem'', ''p'', ''x@mail.com'')';
EXEC #Rej '4.1.b email is UNIQUE', N'INSERT INTO dbo.Users (first_name, last_name, username, password, email) VALUES (''A'', ''B'', ''new.user'', ''p'', ''ahmed.salem@mail.com'')';
EXEC #Rej '4.1.b plate_no is UNIQUE', N'INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, zone_id) VALUES (17, ''Car'', ''MAA-1201'', ''LIC-0001'', 1)';
EXEC #Rej '4.1.b license_no is UNIQUE', N'INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, zone_id) VALUES (17, ''Car'', ''NEW-0001'', ''LIC-1201'', 1)';
EXEC #Rej '4.1.b wallet_balance >= 0', N'UPDATE dbo.Customer SET wallet_balance = -1 WHERE customer_id = 17';
EXEC #Rej '4.1.b Address.zone_id is a FK', N'INSERT INTO dbo.Address (description, customer_id, zone_id) VALUES (''X'', 17, 99)';
EXEC #Rej '4.1.b Admin.admin_id is a FK', N'INSERT INTO dbo.Admin (admin_id) VALUES (999)';
EXEC #Rej '4.1.b UNIQUE (customer_id, card_no)', N'INSERT INTO dbo.Card (card_no, card_holder_name, expiration_date, customer_id) VALUES (''4111111111111111'', ''A'', ''2031-01-01'', 17)';
EXEC #Rej '4.1.b one business per partner', N'INSERT INTO dbo.Business (name, opening_hour, closing_hour, expected_delivery_time, partner_id, zone_id) VALUES (''X'', ''09:00'', ''17:00'', 10, 4, 1)';
EXEC #Rej '4.1.b expected_delivery_time > 0', N'UPDATE dbo.Business SET expected_delivery_time = 0 WHERE business_id = 1';
EXEC #Rej '4.1.b price > 0', N'UPDATE dbo.Product SET price = 0 WHERE product_id = 1';
EXEC #Rej '4.1.b discount_amount <= 50% of price', N'UPDATE dbo.Product SET discount_amount = 30.01 WHERE product_id = 1';
EXEC #Rej '4.1.b discount_amount >= 0', N'UPDATE dbo.Product SET discount_amount = -1 WHERE product_id = 1';
EXEC #Rej '4.1.b promo_code is UNIQUE', N'INSERT INTO dbo.Voucher (promo_code, is_percentage, amount, expiry_date, customer_id) VALUES (''SAVE10'', 0, 5, ''2030-01-01'', 18)';
EXEC #Rej '4.1.b voucher amount > 0', N'UPDATE dbo.Voucher SET amount = 0 WHERE voucher_id = 3';
EXEC #Rej '4.1.b CartItem.quantity <= 10', N'UPDATE dbo.CartItem SET quantity = 11 WHERE cart_id = 9 AND product_id = 1';
EXEC #Rej '4.1.b CartItem.quantity >= 1', N'UPDATE dbo.CartItem SET quantity = 0 WHERE cart_id = 9 AND product_id = 1';
EXEC #Rej '4.1.b one order per cart', N'INSERT INTO dbo.Orders (order_date, total_amount, cart_id, zone_id) VALUES (GETDATE(), 10, 1, 1)';
EXEC #Rej '4.1.b UNIQUE (order_id, business_id)', N'INSERT INTO dbo.SubOrder (total_price, delivery_fee, order_id, business_id) VALUES (10, 20, 1, 1)';
EXEC #Rej '4.1.b one delivery per SubOrder', N'INSERT INTO dbo.Delivery (assigned_at, suborder_id, rider_id) VALUES (GETDATE(), 1, 12)';
EXEC #Rej '4.1.b rider_rating 1..5', N'UPDATE dbo.Delivery SET rider_rating = 6 WHERE delivery_id = 1';
EXEC #Rej '4.1.b one payment per order', N'INSERT INTO dbo.Payment (amount, method, transaction_date, order_id) VALUES (10, ''Cash'', GETDATE(), 1)';
EXEC #Rej '4.1.b refunded_amount <= amount', N'UPDATE dbo.Payment SET refunded_amount = 260.01 WHERE payment_id = 1';
EXEC #Rej '4.1.b one feedback per SubOrder', N'INSERT INTO dbo.Feedback (headline, rating, suborder_id) VALUES (''X'', 5, 1)';
EXEC #Rej '4.1.b rating 1..5', N'UPDATE dbo.Feedback SET rating = 0 WHERE feedback_id = 1';
EXEC #V '4.1.b only the CHECK constraints of Appendix A (none on status/type columns)', N'SELECT STRING_AGG(OBJECT_NAME(parent_object_id), '','') WITHIN GROUP (ORDER BY OBJECT_NAME(parent_object_id)) FROM sys.check_constraints', 'Business,CartItem,Customer,Delivery,Feedback,Payment,Product,Product,Voucher,Zone';
EXEC #V 'Section 1: no procedure uses a transaction', N'SELECT COUNT(*) FROM sys.sql_modules WHERE definition LIKE ''%BEGIN TRAN%'' OR definition LIKE ''%COMMIT%'' OR definition LIKE ''%ROLLBACK%''', '0';
GO
-- A fresh reset: the rejected inserts above used up identity values.
EXEC #Reset;
EXEC #Exec '4.1.b rows inserted with defaults only', N'
	INSERT INTO dbo.Users (first_name, last_name, username, password, email) VALUES (''D'', ''F'', ''defaults'', ''p'', ''defaults@mail.com'');
	INSERT INTO dbo.Admin (admin_id) VALUES (25);
	INSERT INTO dbo.Customer (customer_id) VALUES (25);
	INSERT INTO dbo.Partner (partner_id) VALUES (25);
	INSERT INTO dbo.Rider (rider_id, vehicle_type, plate_no, license_no, zone_id) VALUES (25, ''Car'', ''DEF-1'', ''DEF-1'', 1);
	INSERT INTO dbo.Address (description, customer_id, zone_id) VALUES (''X'', 25, 1);
	INSERT INTO dbo.Cart (customer_id, address_id) VALUES (25, 13);
	INSERT INTO dbo.Business (name, opening_hour, closing_hour, expected_delivery_time, partner_id, zone_id) VALUES (''B'', ''09:00'', ''17:00'', 10, 25, 1);
	INSERT INTO dbo.Product (name, category, price, business_id) VALUES (''P'', ''C'', 10, 9);
	INSERT INTO dbo.Voucher (promo_code, is_percentage, amount, expiry_date, customer_id) VALUES (''DEF'', 0, 5, ''2030-01-01'', 25);
	INSERT INTO dbo.Orders (order_date, total_amount, cart_id, zone_id) VALUES (GETDATE(), 10, 16, 1);
	INSERT INTO dbo.SubOrder (total_price, delivery_fee, order_id, business_id) VALUES (10, 20, 9, 9);
	INSERT INTO dbo.Payment (amount, method, transaction_date, order_id) VALUES (10, ''Cash'', GETDATE(), 9);
	INSERT INTO dbo.Feedback (headline, rating, suborder_id) VALUES (''H'', 5, 13);';
EXEC #V '4.1.b defaults', N'SELECT CONCAT(u.account_status, ''/'', a.role, ''/'', c.wallet_balance, ''/'', ad.is_active, ''/'', ca.status, ''/'',
		b.status, ''/'', p.discount_amount, ''/'', p.is_available, ''/'', v.status, ''/'', o.status, ''/'', o.discount_amount, ''/'',
		s.status, ''/'', pay.currency, ''/'', pay.refunded_amount, ''/'', r.is_available, ''/'',
		CASE WHEN ca.created_at IS NOT NULL AND f.feedback_date IS NOT NULL THEN ''dates'' END)
	FROM dbo.Users u, dbo.Admin a, dbo.Customer c, dbo.Address ad, dbo.Cart ca, dbo.Business b, dbo.Product p, dbo.Voucher v,
		dbo.Orders o, dbo.SubOrder s, dbo.Payment pay, dbo.Rider r, dbo.Feedback f
	WHERE u.user_id = 25 AND a.admin_id = 25 AND c.customer_id = 25 AND ad.address_id = 13 AND ca.cart_id = 16 AND b.business_id = 9
		AND p.product_id = 21 AND v.voucher_id = 8 AND o.order_id = 9 AND s.suborder_id = 13 AND pay.order_id = 9 AND r.rider_id = 25
		AND f.suborder_id = 13', 'Active/Super Admin/0.00/1/Active/Pending/0.00/1/Unused/Placed/0.00/Placed/EGP/0.00/1/dates';
GO

/* =============================== 4.2 Views =============================== */
EXEC #Reset;
EXEC #V '4.2.a all businesses listed', N'SELECT COUNT(*) FROM dbo.allBusinessProfiles', '8';
EXEC #V '4.2.a suspended business row', N'SELECT CONCAT(business_type, ''/'', zone_name, ''/'', partner_name, ''/'', status, ''/'', CONVERT(VARCHAR(5), opening_hour, 108), ''/'', CONVERT(VARCHAR(5), closing_hour, 108)) FROM dbo.allBusinessProfiles WHERE business_id = 6', 'Restaurant/New Cairo/Rania Ezz/Suspended/10:00/02:00';
EXEC #V '4.2.b all zones, Active businesses only', N'SELECT STRING_AGG(CONCAT(zone_id, '':'', business_count), '','') WITHIN GROUP (ORDER BY zone_id) FROM dbo.BusinessesPerZone', '1:3,2:1,3:1,4:0';
EXEC #V '4.2.c business without feedback', N'SELECT CONCAT(ISNULL(CAST(avg_rating AS VARCHAR(10)), ''NULL''), ''/'', ratings_count) FROM dbo.BusinessRatingsSummary WHERE business_id = 2', 'NULL/0';
EXEC #V '4.2.d expired and Used vouchers hidden', N'SELECT STRING_AGG(CAST(voucher_id AS VARCHAR(10)), '','') WITHIN GROUP (ORDER BY voucher_id) FROM dbo.ActiveVouchers', '3,4,7';
EXEC #V '4.2.e Pending only', N'SELECT STRING_AGG(CAST(business_id AS VARCHAR(10)), '','') FROM dbo.PendingBusinessApprovals', '5';
EXEC #V '4.2.f rider without deliveries', N'SELECT CONCAT(rider_name, ''/'', zone_name, ''/'', completed_deliveries, ''/'', ISNULL(CAST(avg_rating AS VARCHAR(10)), ''NULL'')) FROM dbo.RiderPerformanceSummary WHERE rider_id = 14', 'Yehia Saad/Maadi/0/NULL';
EXEC #V '4.2.g at most 10 rows', N'SELECT COUNT(*) FROM dbo.TopSellingProducts', '10';
EXEC #V '4.2.h every zone', N'SELECT STRING_AGG(CONCAT(zone_id, '':'', delivery_count), '','') WITHIN GROUP (ORDER BY zone_id) FROM dbo.ZoneDeliveryPerformance', '1:4,2:1,3:1,4:0';
GO
EXEC #Reset;
EXEC #T '4.2 setup: register a pharmacy in Heliopolis', N'dbo.Register_Business 11, ''Mai Pharmacy'', NULL, NULL, 4, ''08:00'', ''20:00'', 15, ''02200000011'', ''Pharmacy'', NULL, NULL, ''Retail''', 0;
EXEC #V '4.2.a new business is listed as Pending', N'SELECT CONCAT(business_type, ''/'', zone_name, ''/'', partner_name, ''/'', status) FROM dbo.allBusinessProfiles WHERE business_id = 9', 'Pharmacy/Heliopolis/Mai Lotfy/Pending';
EXEC #V '4.2.e new business awaits approval', N'SELECT STRING_AGG(CAST(business_id AS VARCHAR(10)), '','') WITHIN GROUP (ORDER BY business_id) FROM dbo.PendingBusinessApprovals', '5,9';
EXEC #T '4.2 setup: approve it', N'dbo.Approve_Business 9, 1', 0;
EXEC #V '4.2.b counted once Active', N'SELECT business_count FROM dbo.BusinessesPerZone WHERE zone_id = 4', '1';
EXEC #V '4.2.e no longer Pending', N'SELECT STRING_AGG(CAST(business_id AS VARCHAR(10)), '','') FROM dbo.PendingBusinessApprovals', '5';
GO
EXEC #Reset;
EXEC #T '4.2 setup: cancel order 7', N'dbo.Cancel_Order 7', 0;
EXEC #V '4.2.g cancelled SubOrders do not count (ties by product_id)', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold), '','') WITHIN GROUP (ORDER BY units_sold DESC, product_id) FROM dbo.TopSellingProducts', '2:3,1:2,3:2,8:2,12:2,5:1,6:1,10:1,11:1,16:1';
EXEC #V '4.2.g revenue uses the frozen unit price', N'SELECT total_revenue FROM dbo.TopSellingProducts WHERE product_id = 5', '100.00';
EXEC #T '4.2 setup: feedback on SubOrder 2', N'dbo.Submit_Feedback 2, ''OK'', NULL, 3', 0;
EXEC #V '4.2.c new feedback is averaged', N'SELECT CONCAT(avg_rating, ''/'', ratings_count) FROM dbo.BusinessRatingsSummary WHERE business_id = 2', '3.00/1';
EXEC #T '4.2 setup: deliver delivery 9', N'dbo.Mark_Delivered 9', 0;
EXEC #V '4.2.f new delivery counted', N'SELECT completed_deliveries FROM dbo.RiderPerformanceSummary WHERE rider_id = 12', '3';
EXEC #V '4.2.h new delivery counted', N'SELECT delivery_count FROM dbo.ZoneDeliveryPerformance WHERE zone_id = 1', '5';
GO

/* =============================== 4.3 Accounts =============================== */
EXEC #Reset;
EXEC #T '4.3.a NULL middle name and dob are fine', N'dbo.Customer_Register ''Mona'', NULL, ''Ali'', ''mona.ali'', ''Pass@030'', ''mona.ali@mail.com'', ''01000000030'', NULL', 0;
EXEC #V '4.3.a customer row', N'SELECT CONCAT(c.wallet_balance, ''/'', u.account_status) FROM dbo.Customer c JOIN dbo.Users u ON u.user_id = c.customer_id WHERE u.username = ''mona.ali''', '0.00/Active';
EXEC #T '4.3.a NULL first name', N'dbo.Customer_Register NULL, NULL, ''Ali'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL', -1;
EXEC #T '4.3.a empty username', N'dbo.Customer_Register ''X'', NULL, ''Y'', '''', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL', -1;
EXEC #T '4.3.a phone with letters', N'dbo.Customer_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''0100000003a'', NULL', -1;
EXEC #T '4.3.a dob in the future', N'dbo.Customer_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', ''2999-01-01''', -1;
EXEC #T '4.3.a duplicate email', N'dbo.Customer_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''sara.mostafa@mail.com'', ''01000000031'', NULL', -2;
EXEC #T '4.3.b duplicate username', N'dbo.Partner_Register ''X'', NULL, ''Y'', ''tarek.fouad'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL', -2;
EXEC #T '4.3.c missing zone', N'dbo.Rider_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Car'', ''NEW-1'', ''NEW-1'', 99', -1;
EXEC #T '4.3.c NULL vehicle', N'dbo.Rider_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, NULL, ''NEW-1'', ''NEW-1'', 1', -1;
EXEC #T '4.3.c duplicate license', N'dbo.Rider_Register ''X'', NULL, ''Y'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Car'', ''NEW-1'', ''LIC-1302'', 1', -2;
EXEC #V '4.3.d NULL password', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', NULL)', '0';
EXEC #V '4.3.d a rider is not a customer', N'SELECT dbo.CustomerLoginValidation(''ali.ibrahim'', ''Pass@012'')', '0';
EXEC #V '4.3.e wrong password', N'SELECT dbo.PartnerLoginValidation(''tarek.fouad'', ''Pass@005'')', '0';
EXEC #V '4.3.f a partner is not a rider', N'SELECT dbo.RiderLoginValidation(''tarek.fouad'', ''Pass@004'')', '0';
EXEC #V '4.3.g zone admin', N'SELECT dbo.AdminLoginValidation(''karim.adel'', ''Pass@002'')', '1';
EXEC #T '4.3.h admin changes password', N'dbo.Change_Password 1, ''Pass@001'', ''Admin@1'', ''Admin@1'', @ok OUTPUT', 0;
EXEC #V '4.3.h success = 1', N'SELECT ok FROM #Last', '1';
EXEC #V '4.3.h new password works', N'SELECT dbo.AdminLoginValidation(''mona.hassan'', ''Admin@1'')', '1';
EXEC #T '4.3.h missing user', N'dbo.Change_Password 999, ''Pass@001'', ''New@1'', ''New@1'', @ok OUTPUT', -1;
EXEC #V '4.3.h success = 0', N'SELECT ok FROM #Last', '0';
EXEC #T '4.3.h NULL new password', N'dbo.Change_Password 17, ''Pass@017'', NULL, NULL, @ok OUTPUT', -1;
EXEC #V '4.3.d password is case-sensitive', N'SELECT CONCAT(dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017''), dbo.CustomerLoginValidation(''ahmed.salem'', ''pass@017''), dbo.CustomerLoginValidation(''ahmed.salem'', ''PASS@017''))', '100';
EXEC #V '4.3.e-g password is case-sensitive', N'SELECT CONCAT(dbo.PartnerLoginValidation(''tarek.fouad'', ''pass@004''), dbo.RiderLoginValidation(''ali.ibrahim'', ''PASS@012''), dbo.AdminLoginValidation(''karim.adel'', ''pass@002''))', '000';
EXEC #T '4.3.h old password in the wrong case', N'dbo.Change_Password 17, ''pass@017'', ''New@17'', ''New@17'', @ok OUTPUT', -1;
EXEC #T '4.3.h repeat differs only in case', N'dbo.Change_Password 17, ''Pass@017'', ''New@17'', ''new@17'', @ok OUTPUT', -1;
EXEC #T '4.3.h change to New@17', N'dbo.Change_Password 17, ''Pass@017'', ''New@17'', ''New@17'', @ok OUTPUT', 0;
EXEC #V '4.3.h only the exact new password works', N'SELECT CONCAT(dbo.CustomerLoginValidation(''ahmed.salem'', ''New@17''), dbo.CustomerLoginValidation(''ahmed.salem'', ''new@17''), dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017''))', '100';
GO

/* =============================== 4.4 Admin =============================== */
EXEC #Reset;
EXEC #T '4.4.a NULL role makes a Super Admin', N'dbo.Create_Admin ''A'', NULL, ''B'', ''new.admin'', ''Pass@030'', ''new.admin@mail.com'', ''01000000030'', NULL, NULL, NULL, 1', 0;
EXEC #V '4.4.a Super Admin without zone', N'SELECT CONCAT(a.role, ''/'', ISNULL(CAST(a.zone_id AS VARCHAR(10)), ''NULL'')) FROM dbo.Admin a JOIN dbo.Users u ON u.user_id = a.admin_id WHERE u.username = ''new.admin''', 'Super Admin/NULL';
EXEC #T '4.4.a Zone Admin without zone', N'dbo.Create_Admin ''A'', NULL, ''B'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Zone Admin'', NULL, 1', -1;
EXEC #T '4.4.a unknown role', N'dbo.Create_Admin ''A'', NULL, ''B'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Manager'', 1, 1', -1;
EXEC #T '4.4.a duplicate username', N'dbo.Create_Admin ''A'', NULL, ''B'', ''karim.adel'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Zone Admin'', 1, 1', -2;
EXEC #T '4.4.a a customer as caller', N'dbo.Create_Admin ''A'', NULL, ''B'', ''x.y'', ''Pass@030'', ''x.y@mail.com'', ''01000000031'', NULL, ''Zone Admin'', 1, 17', -3;
EXEC #T '4.4.a lower-case role', N'dbo.Create_Admin ''A'', NULL, ''B'', ''zone.admin2'', ''Pass@031'', ''zone.admin2@mail.com'', ''01000000031'', NULL, ''zone admin'', 1, 1', 0;
EXEC #V '4.4.a role stored exactly as in Section 2.3', N'SELECT CASE WHEN a.role = ''Zone Admin'' COLLATE Latin1_General_CS_AS THEN ''exact'' ELSE a.role END FROM dbo.Admin a JOIN dbo.Users u ON u.user_id = a.admin_id WHERE u.username = ''zone.admin2''', 'exact';
EXEC #T '4.4.b Super Admin approves any zone', N'dbo.Approve_Business 5, 1', 0;
EXEC #T '4.4.b Rejected business', N'dbo.Approve_Business 8, 1', -4;
EXEC #T '4.4.b Suspended business', N'dbo.Approve_Business 6, 1', -4;
EXEC #T '4.4.b a customer as admin', N'dbo.Approve_Business 8, 17', -3;
EXEC #T '4.4.c Active business', N'dbo.Reject_Business 1, 1', -4;
GO
EXEC #Reset;
EXEC #T '4.4.c Zone Admin of the zone rejects', N'dbo.Reject_Business 5, 3', 0;
EXEC #T '4.4.c then it cannot be approved', N'dbo.Approve_Business 5, 3', -4;
EXEC #T '4.4.h zone that does not exist', N'dbo.Assign_Admin_Zone 2, 99, 1', -1;
EXEC #T '4.4.h move Zone Admin 2 to Zamalek', N'dbo.Assign_Admin_Zone 2, 2, 1', 0;
EXEC #T '4.4.d moved admin is now out of scope for Maadi', N'dbo.Suspend_Business 1, 2, ''R''', -3;
EXEC #T '4.4.d moved admin can act on Zamalek', N'dbo.Suspend_Business 4, 2, ''R''', 0;
GO
EXEC #Reset;
EXEC #T '4.4.d Zone Admin suspends in own zone', N'dbo.Suspend_Business 3, 2, ''Audit''', 0;
EXEC #V '4.4.d customer 17 card refund to wallet, order 7 cash', N'SELECT CONCAT((SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17), ''/'', (SELECT refunded_amount FROM dbo.Payment WHERE order_id = 6), ''/'', (SELECT refunded_amount FROM dbo.Payment WHERE order_id = 7), ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 18))', '550.00/50.00/100.00/50.00';
EXEC #V '4.4.d hidden from search', N'SELECT COUNT(*) FROM dbo.Search_Platform(17, ''Seif'')', '0';
EXEC #V '4.4.d counted out of Maadi', N'SELECT business_count FROM dbo.BusinessesPerZone WHERE zone_id = 1', '2';
EXEC #T '4.4.d its products cannot be carted', N'dbo.Add_To_Cart 9, 10, 1, NULL', -4;
EXEC #T '4.4.d carts with its products cannot be checked out', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', -4;
EXEC #T '4.4.d suspend twice', N'dbo.Suspend_Business 3, 1, ''Again''', -4;
EXEC #T '4.4.d Rejected business', N'dbo.Suspend_Business 8, 1, ''R''', -4;
EXEC #T '4.4.e reinstate', N'dbo.Reinstate_Business 3, 1', 0;
EXEC #T '4.4.e products stay hidden', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', -4;
EXEC #T '4.4.e partner re-enables Panadol', N'dbo.Toggle_Product_Status 8, 1', 0;
EXEC #T '4.4.e then the cart checks out', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #T '4.4.e Pending business', N'dbo.Reinstate_Business 5, 1', -4;
EXEC #V '4.4.d/e totals still reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #T '4.4.d setup: checkout cart 9 with WELCOME50 (140 from the wallet)', N'dbo.Checkout_Cart 9, 3, ''Wallet'', NULL', 0;
EXEC #T '4.4.d suspend Seif Pharmacy: one of the two SubOrders of order 9', N'dbo.Suspend_Business 3, 1, ''Audit''', 0;
EXEC #V '4.4.d order 9 partly cancelled keeps its voucher', N'SELECT CONCAT(o.status, ''/'', o.voucher_id, ''/'', v.status, ''/'', p.refunded_amount) FROM dbo.Orders o JOIN dbo.Voucher v ON v.voucher_id = o.voucher_id JOIN dbo.Payment p ON p.order_id = o.order_id WHERE o.order_id = 9', 'Placed/3/Used/110.00';
EXEC #T '4.4.d suspend Koshary: the last SubOrder of order 9', N'dbo.Suspend_Business 1, 1, ''Audit''', 0;
EXEC #V '4.4.d refund capped at the payment, voucher back', N'SELECT CONCAT(o.status, ''/'', ISNULL(CAST(o.voucher_id AS VARCHAR(10)), ''NULL''), ''/'', (SELECT status FROM dbo.Voucher WHERE voucher_id = 3), ''/'', p.refunded_amount) FROM dbo.Orders o JOIN dbo.Payment p ON p.order_id = o.order_id WHERE o.order_id = 9', 'Cancelled/NULL/Unused/140.00';
EXEC #V '4.4.d wallet: 500 - 140 + 110 + 50 + 30', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17', '550.00';
EXEC #V '4.4.d picked-up SubOrder 9 untouched', N'SELECT CONCAT((SELECT status FROM dbo.SubOrder WHERE suborder_id = 9), ''/'', (SELECT status FROM dbo.Orders WHERE order_id = 6))', 'Picked Up/In Progress';
EXEC #V '4.4.d totals still reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #T '4.4.f zone name differing only in case', N'dbo.Create_Zone ''maadi'', 10, 1', -2;
EXEC #T '4.4.g new fee', N'dbo.Update_Zone_Fee 1, 22.50, 1', 0;
EXEC #T '4.4.g checkout uses the new fee', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #V '4.4.g SubOrder fees and total', N'SELECT CONCAT((SELECT STRING_AGG(CAST(s.delivery_fee AS VARCHAR(20)), '','') FROM dbo.SubOrder s JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.cart_id = 9), ''/'', (SELECT total_amount FROM dbo.Orders WHERE cart_id = 9))', '22.50,22.50/195.00';
EXEC #T '4.4.i Zone Admin issues a voucher', N'dbo.Issue_Voucher 18, ''ZONE5'', 0, 5, ''2030-12-31'', 2', 0;
EXEC #T '4.4.i percentage above 100', N'dbo.Issue_Voucher 18, ''P101'', 1, 101, ''2030-12-31'', 1', -1;
EXEC #T '4.4.i amount 0', N'dbo.Issue_Voucher 18, ''ZERO'', 0, 0, ''2030-12-31'', 1', -1;
EXEC #T '4.4.i a customer as admin', N'dbo.Issue_Voucher 18, ''X1'', 0, 5, ''2030-12-31'', 17', -3;
DECLARE @y NVARCHAR(10) = CONVERT(NVARCHAR(10), DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 23), @t NVARCHAR(10) = CONVERT(NVARCHAR(10), CAST(GETDATE() AS DATE), 23);
DECLARE @c1 NVARCHAR(MAX) = N'dbo.Issue_Voucher 18, ''OLDY'', 0, 5, ''' + @y + N''', 1', @c2 NVARCHAR(MAX) = N'dbo.Issue_Voucher 18, ''TODAY'', 0, 5, ''' + @t + N''', 1';
EXEC #T '4.4.i expired yesterday', @c1, -1;
EXEC #T '4.4.i expires today', @c2, 0;
EXEC #V '4.2.d a voucher expiring today is still active', N'SELECT COUNT(*) FROM dbo.ActiveVouchers WHERE promo_code = ''TODAY''', '1';
GO
EXEC #Reset;
EXEC #T '4.4.j Zone Admin of a zone where the customer has an inactive address', N'dbo.Blacklist_Customer 17, 3, ''Fraud''', 0;
EXEC #V '4.4.j picked-up and delivered orders kept', N'SELECT STRING_AGG(CONCAT(order_id, '':'', status), '','') WITHIN GROUP (ORDER BY order_id) FROM dbo.My_Order_History(17)', '1:Delivered,6:In Progress';
EXEC #V '4.4.j Unused vouchers deleted', N'SELECT COUNT(*) FROM dbo.Voucher WHERE customer_id = 17', '0';
EXEC #T '4.4.j blacklisted: no new cart', N'dbo.Create_Cart 17', -3;
EXEC #T '4.4.j blacklisted: no reorder', N'dbo.Reorder 1, 10', -3;
EXEC #T '4.4.j blacklisted: no voucher', N'dbo.Issue_Voucher 17, ''BACK'', 0, 5, ''2030-12-31'', 1', -3;
EXEC #T '4.4.k not the blacklisting admin (Super Admin)', N'dbo.Lift_Customer_Blacklist 17, 1', -3;
EXEC #T '4.4.k blacklisting admin lifts', N'dbo.Lift_Customer_Blacklist 17, 3', 0;
EXEC #T '4.4.k lifted customer is no longer blocked (address 1 already has a cart)', N'dbo.Create_Cart 17', -2;
EXEC #T '4.4.k customer that is not blacklisted', N'dbo.Lift_Customer_Blacklist 18, 1', -4;
GO
EXEC #Reset;
EXEC #T '4.4.j cancels the Placed cash order, keeps the Used voucher', N'dbo.Blacklist_Customer 18, 2, ''Chargebacks''', 0;
EXEC #V '4.4.j order 7, refund, wallet, vouchers left', N'SELECT CONCAT((SELECT status FROM dbo.Orders WHERE order_id = 7), ''/'', (SELECT refunded_amount FROM dbo.Payment WHERE order_id = 7), ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 18), ''/'', (SELECT STRING_AGG(CAST(voucher_id AS VARCHAR(10)), '','') FROM dbo.Voucher WHERE customer_id = 18))', 'Cancelled/100.00/50.00/1';
EXEC #T '4.4.j NULL reason', N'dbo.Blacklist_Customer 19, 1, NULL', -1;
EXEC #T '4.4.j a customer as admin', N'dbo.Blacklist_Customer 19, 17, ''R''', -3;
EXEC #V '4.4.j totals still reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #V '4.4.l Zamalek in September', N'SELECT CONCAT(zone_id, ''/'', zone_name, ''/'', number_of_orders, ''/'', avg_order_total, ''/'', platform_commission) FROM dbo.ZoneOrderReport(2, ''2026-09-01'', ''2026-09-30'')', '2/Zamalek/1/277.00/28.00';
EXEC #V '4.4.l one-day range', N'SELECT CONCAT(number_of_orders, ''/'', avg_order_total, ''/'', platform_commission) FROM dbo.ZoneOrderReport(1, ''2026-09-01'', ''2026-09-01'')', '1/260.00/22.00';
EXEC #V '4.4.m one-day range, tie by rider_id', N'SELECT STRING_AGG(CONCAT(rider_rank, '':'', rider_id, '':'', completed_delivery_count), '','') WITHIN GROUP (ORDER BY rider_rank) FROM dbo.TopRiders(''2026-09-01'', ''2026-09-01'')', '1:12:1,2:13:1';
EXEC #V '4.4.m period without deliveries', N'SELECT COUNT(*) FROM dbo.TopRiders(''2027-01-01'', ''2027-01-31'')', '0';
EXEC #V '4.4.n one zone, one type', N'SELECT STRING_AGG(CONCAT(zone_name, ''/'', business_type, ''/'', number_of_suborders, ''/'', gross_sales, ''/'', delivery_fees, ''/'', platform_commission), '','') FROM dbo.Daily_Revenue_Report(''2026-09-01'')', 'Maadi/Restaurant/2/220.00/40.00/22.00';
EXEC #V '4.4.n split by type', N'SELECT STRING_AGG(CONCAT(zone_name, ''/'', business_type, ''/'', number_of_suborders, ''/'', gross_sales, ''/'', delivery_fees, ''/'', platform_commission), '','') WITHIN GROUP (ORDER BY business_type) FROM dbo.Daily_Revenue_Report(''2026-09-20'')', 'Maadi/Pharmacy/1/30.00/20.00/3.00,Maadi/Restaurant/1/120.00/20.00/12.00';
EXEC #V '4.4.n only a cancelled order that day', N'SELECT COUNT(*) FROM dbo.Daily_Revenue_Report(''2026-09-10'')', '0';
EXEC #T '4.4 setup: cancel order 8', N'dbo.Cancel_Order 8', 0;
EXEC #V '4.4.l cancelled order left out', N'SELECT CONCAT(number_of_orders, ''/'', avg_order_total, ''/'', platform_commission) FROM dbo.ZoneOrderReport(1, ''2026-09-01'', ''2026-09-30'')', '4/172.50/58.00';
GO

/* =============================== 4.5 Partner =============================== */
EXEC #Reset;
EXEC #T '4.5.a re-register a Rejected business as a restaurant', N'dbo.Register_Business 24, ''Nile Sweets 2'', NULL, ''www.nile.example'', 1, ''10:00'', ''23:00'', 20, ''02200000099'', ''Restaurant'', ''Lebanese'', ''Desserts'', NULL', 0;
EXEC #V '4.5.a same row, new data', N'SELECT CONCAT(COUNT(*), ''/'', MAX(business_id), ''/'', MAX(name), ''/'', MAX(status), ''/'', MAX(zone_id), ''/'', MAX(expected_delivery_time), ''/'', MAX(link_website)) FROM dbo.Business WHERE partner_id = 24', '1/8/Nile Sweets 2/Pending/1/20/www.nile.example';
EXEC #V '4.5.a subtype and phones replaced', N'SELECT CONCAT((SELECT cuisine_type + ''/'' + food_category FROM dbo.Restaurant WHERE business_id = 8), ''/'', (SELECT STRING_AGG(phone, '','') FROM dbo.Business_Phone WHERE business_id = 8))', 'Lebanese/Desserts/02200000099';
EXEC #T '4.5.a partner whose business is Active', N'dbo.Register_Business 5, ''X'', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''02200000098'', ''Pharmacy'', NULL, NULL, ''Retail''', -2;
EXEC #T '4.5.a restaurant without cuisine_type', N'dbo.Register_Business 11, ''X'', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''02200000098'', ''Restaurant'', NULL, ''Pizza'', NULL', -1;
EXEC #T '4.5.a phone with letters', N'dbo.Register_Business 11, ''X'', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''0220000009x'', ''Pharmacy'', NULL, NULL, ''Retail''', -1;
EXEC #T '4.5.a empty name', N'dbo.Register_Business 11, '''', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''02200000098'', ''Pharmacy'', NULL, NULL, ''Retail''', -1;
EXEC #T '4.5.a NULL hours', N'dbo.Register_Business 11, ''X'', NULL, NULL, 1, NULL, ''23:00'', 20, ''02200000098'', ''Pharmacy'', NULL, NULL, ''Retail''', -1;
EXEC #T '4.5.a unknown business type', N'dbo.Register_Business 11, ''X'', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''02200000098'', ''Bakery'', NULL, NULL, NULL', -1;
EXEC #T '4.5.a a customer as partner (our choice)', N'dbo.Register_Business 17, ''X'', NULL, NULL, 1, ''10:00'', ''23:00'', 20, ''02200000098'', ''Pharmacy'', NULL, NULL, ''Retail''', -3;
EXEC #T '4.5.b overnight hours', N'dbo.Update_Business_Info 1, ''22:00'', ''06:00'', NULL, ''www.koshary.example''', 0;
EXEC #T '4.5.b a phone another business already has', N'dbo.Update_Business_Info 1, ''22:00'', ''06:00'', ''02200000002'', NULL', 0;
EXEC #V '4.5.b phones of business 1', N'SELECT COUNT(*) FROM dbo.Business_Phone WHERE business_id = 1', '3';
EXEC #T '4.5.c update keeps the discount', N'dbo.Upsert_Product 2, 5, ''Margherita XL'', NULL, ''Pizza'', 140.00, 1', 0;
EXEC #V '4.5.c updated product', N'SELECT CONCAT(name, ''/'', price, ''/'', discount_amount) FROM dbo.Product WHERE product_id = 5', 'Margherita XL/140.00/20.00';
EXEC #T '4.5.c insert an unavailable product', N'dbo.Upsert_Product 3, NULL, ''Gloves'', NULL, ''Hygiene'', 12.00, 0', 0;
EXEC #V '4.5.c inserted product', N'SELECT CONCAT(product_id, ''/'', business_id, ''/'', discount_amount, ''/'', is_available) FROM dbo.Product WHERE name = ''Gloves''', '21/3/0.00/0';
EXEC #T '4.5.c negative price', N'dbo.Upsert_Product 3, NULL, ''Gloves'', NULL, ''Hygiene'', -1, 1', -1;
EXEC #T '4.5.c NULL name', N'dbo.Upsert_Product 3, NULL, NULL, NULL, ''Hygiene'', 5, 1', -1;
EXEC #T '4.5.c business that does not exist', N'dbo.Upsert_Product 99, NULL, ''X'', NULL, ''Hygiene'', 5, 1', -1;
EXEC #T '4.5.c update a product of a Suspended business', N'dbo.Upsert_Product 6, 15, ''Basbousa'', NULL, ''Desserts'', 35, 0', -4;
EXEC #T '4.5.d reactivate in an Active business', N'dbo.Toggle_Product_Status 4, 1', 0;
EXEC #T '4.5.d product that does not exist', N'dbo.Toggle_Product_Status 99, 1', -1;
EXEC #T '4.5.e discount exactly 50%', N'dbo.Set_Product_Promotion 2, 20.00', 0;
EXEC #T '4.5.e NULL discount', N'dbo.Set_Product_Promotion 2, NULL', -1;
GO
EXEC #Reset;
EXEC #V '4.5.f Seif Pharmacy in September', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold, '':'', revenue_per_product), '','') WITHIN GROUP (ORDER BY product_id) FROM dbo.BusinessSalesReport(3, ''2026-09-01'', ''2026-09-30'')', '8:2:90.00,9:1:80.00,10:1:30.00';
EXEC #V '4.5.f date range respected', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold), '','') FROM dbo.BusinessSalesReport(3, ''2026-09-01'', ''2026-09-02'')', '8:2';
EXEC #V '4.5.f cancelled SubOrder left out', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold), '','') WITHIN GROUP (ORDER BY product_id) FROM dbo.BusinessSalesReport(2, ''2026-09-01'', ''2026-09-30'')', '5:1,6:1';
EXEC #V '4.5.f only cancelled sales', N'SELECT COUNT(*) FROM dbo.BusinessSalesReport(6, ''2026-09-01'', ''2026-09-30'')', '0';
EXEC #V '4.5.g business without feedback', N'SELECT CONCAT(ISNULL(CAST(avg_rating AS VARCHAR(10)), ''NULL''), ''/'', number_of_feedbacks, ''/'', five_star, ''/'', one_star) FROM dbo.BusinessFeedbackOverview(2)', 'NULL/0/0/0';
EXEC #T '4.5 setup: cancel order 7', N'dbo.Cancel_Order 7', 0;
EXEC #V '4.5.f cancelled order no longer counted', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold), '','') WITHIN GROUP (ORDER BY product_id) FROM dbo.BusinessSalesReport(3, ''2026-09-01'', ''2026-09-30'')', '8:2,10:1';
GO

/* =============================== 4.6 Customer: addresses, cards, carts =============================== */
EXEC #Reset;
EXEC #T '4.6.a second customer address', N'dbo.Add_Customer_Address 20, ''Heliopolis Villa'', 4', 0;
EXEC #V '4.6.a only the new one is active', N'SELECT STRING_AGG(CAST(address_id AS VARCHAR(10)), '','') FROM dbo.Address WHERE customer_id = 20 AND is_active = 1', '13';
EXEC #T '4.6.b delete an unused address, lower-case action', N'dbo.Update_Delete_Customer_Address 20, 9, NULL, NULL, ''delete''', 0;
EXEC #T '4.6.b address of a Placed order', N'dbo.Update_Delete_Customer_Address 22, 8, ''X'', 1, ''Update''', -4;
EXEC #T '4.6.b delete an address that has carts', N'dbo.Update_Delete_Customer_Address 20, 6, NULL, NULL, ''Delete''', -4;
EXEC #T '4.6.b empty description', N'dbo.Update_Delete_Customer_Address 20, 12, '''', 3, ''Update''', -1;
EXEC #T '4.6.b Remove, the Section 2.3 word for Delete', N'dbo.Update_Delete_Customer_Address 17, 10, NULL, NULL, ''Remove''', 0;
EXEC #V '4.6.b removed', N'SELECT COUNT(*) FROM dbo.Address WHERE address_id = 10', '0';
EXEC #T '4.6.b unknown action', N'dbo.Update_Delete_Customer_Address 17, 2, NULL, NULL, ''Add''', -1;
EXEC #T '4.6.c back to an older address', N'dbo.Change_Active_Address 20, 12', 0;
EXEC #T '4.6.e cart for the new active address', N'dbo.Create_Cart 20', 0;
EXEC #V '4.6.e new cart', N'SELECT CONCAT(cart_id, ''/'', status, ''/'', address_id) FROM dbo.Cart WHERE cart_id = (SELECT MAX(cart_id) FROM dbo.Cart)', '16/Active/12';
EXEC #T '4.6.f add to it', N'dbo.Add_To_Cart 16, 17, 2, NULL', 0;
EXEC #T '4.6.c old cart of address 6 cannot be edited now', N'dbo.Add_To_Cart 13, 16, 1, NULL', -4;
EXEC #T '4.6.d same card number for another customer', N'dbo.Add_Card 18, ''4111111111111111'', ''Sara Mostafa'', ''2031-01-31''', 0;
DECLARE @y NVARCHAR(10) = CONVERT(NVARCHAR(10), DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 23);
DECLARE @c NVARCHAR(MAX) = N'dbo.Add_Card 18, ''4999999999999999'', ''Sara Mostafa'', ''' + @y + N'''';
EXEC #T '4.6.d expired yesterday', @c, -1;
GO
EXEC #Reset;
EXEC #T '4.6.f fill a line up to 10', N'dbo.Add_To_Cart 11, 13, 10, NULL', 0;
EXEC #T '4.6.f one more is over 10', N'dbo.Add_To_Cart 11, 13, 1, NULL', -6;
EXEC #T '4.6.f product of a Pending business', N'dbo.Add_To_Cart 11, 14, 1, NULL', -4;
EXEC #T '4.6.f product of a Rejected business', N'dbo.Add_To_Cart 9, 20, 1, NULL', -4;
EXEC #T '4.6.f Active business in another zone', N'dbo.Add_To_Cart 9, 16, 1, NULL', -5;
EXEC #T '4.6.f NULL quantity', N'dbo.Add_To_Cart 9, 2, NULL, NULL', -1;
EXEC #T '4.6.g remove the only item', N'dbo.Remove_From_Cart 11, 12', 0;
EXEC #T '4.6.g remove it again (our choice)', N'dbo.Remove_From_Cart 11, 12', -9;
EXEC #T '4.6.i 10 Green Tea Ice Cream', N'dbo.Checkout_Cart 11, NULL, ''Cash'', NULL', 0;
EXEC #V '4.6.i 10 x 60 + 25', N'SELECT total_amount FROM dbo.Orders WHERE cart_id = 11', '625.00';
EXEC #T '4.6.g empty cart 13', N'dbo.Remove_From_Cart 13, 17', 0;
EXEC #T '4.6.i checkout the emptied cart', N'dbo.Checkout_Cart 13, NULL, ''Cash'', NULL', -9;
EXEC #T '4.6 setup: new customer', N'dbo.Customer_Register ''No'', NULL, ''Address'', ''no.address'', ''Pass@030'', ''no.address@mail.com'', ''01000000030'', NULL', 0;
EXEC #T '4.6.e customer without an address (our choice)', N'dbo.Create_Cart 25', -1;
EXEC #V '4.8.a customer without an address finds nothing', N'SELECT COUNT(*) FROM dbo.Search_Platform(25, ''a'')', '0';
EXEC #V '4.6.q customer without an address gets nothing', N'SELECT COUNT(*) FROM dbo.Recommended_Products(25)', '0';
GO
EXEC #Reset;
EXEC #T '4.6.h setup: 100% voucher', N'dbo.Issue_Voucher 17, ''FREE100'', 1, 100, ''2030-12-31'', 1', 0;
EXEC #V '4.6.h 100% of the subtotal', N'SELECT dbo.Calculate_Voucher_Discount(8, 80.00)', '80.00';
EXEC #V '4.6.h fixed amount larger than the subtotal', N'SELECT dbo.Calculate_Voucher_Discount(3, 49.99)', '49.99';
EXEC #V '4.6.h voucher of another customer still computes', N'SELECT dbo.Calculate_Voucher_Discount(7, 80.00)', '20.00';
EXEC #V '4.6.h does not change the voucher', N'SELECT status FROM dbo.Voucher WHERE voucher_id = 8', 'Unused';
GO

/* =============================== 4.6 Checkout =============================== */
EXEC #Reset;
EXEC #T '4.6.i percentage voucher, cash', N'dbo.Checkout_Cart 9, 4, ''Cash'', NULL', 0;
EXEC #V '4.6.i order: 150 - 15 + 2 x 20', N'SELECT CONCAT(order_id, ''/'', status, ''/'', discount_amount, ''/'', total_amount, ''/'', zone_id, ''/'', voucher_id) FROM dbo.Orders WHERE cart_id = 9', '9/Placed/15.00/175.00/1/4';
EXEC #V '4.6.i cash payment has no card, wallet untouched', N'SELECT CONCAT(p.method, ''/'', p.amount, ''/'', ISNULL(CAST(p.card_id AS VARCHAR(10)), ''NULL''), ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17)) FROM dbo.Payment p WHERE p.order_id = 9', 'Cash/175.00/NULL/500.00';
EXEC #V '4.6.i deliveries assigned at the order time', N'SELECT COUNT(*) FROM dbo.Delivery d JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.order_id = 9 AND d.assigned_at = o.order_date AND s.status = ''Assigned''', '2';
EXEC #V '4.6.i rider sees the new deliveries', N'SELECT COUNT(*) FROM dbo.My_Active_Deliveries(12) WHERE order_id = 9', '1';
EXEC #V '4.8.d counted today', N'SELECT orders_today FROM dbo.Platform_Health_Snapshot()', '1';
EXEC #T '4.6.i same cart again', N'dbo.Checkout_Cart 9, 4, ''Cash'', NULL', -4;
EXEC #T '4.6.e address 1 is free for a new cart', N'dbo.Create_Cart 17', 0;
EXEC #T '4.6.k address 1 has an Active cart again', N'dbo.Reorder 1, 1', -2;
EXEC #V '4.8.b totals reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #T '4.6.i setup: a third business in the cart', N'dbo.Add_To_Cart 9, 5, 1, NULL', 0;
EXEC #T '4.6.i three businesses', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #V '4.6.i one SubOrder per business, least-busy rider each time', N'SELECT STRING_AGG(CONCAT(s.business_id, '':'', s.total_price, '':'', d.rider_id), '','') WITHIN GROUP (ORDER BY s.business_id) FROM dbo.SubOrder s JOIN dbo.Delivery d ON d.suborder_id = s.suborder_id WHERE s.order_id = 9', '1:60.00:12,2:100.00:13,3:90.00:12';
EXEC #V '4.6.i discounted unit price frozen', N'SELECT unit_price FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 5', '100.00';
EXEC #V '4.6.i total 250 + 3 x 20', N'SELECT total_amount FROM dbo.Orders WHERE order_id = 9', '310.00';
GO
EXEC #Reset;
EXEC #T '4.6.i setup: fixed voucher bigger than the subtotal', N'dbo.Issue_Voucher 17, ''BIG100'', 0, 100, ''2030-12-31'', 1', 0;
EXEC #T '4.6.i setup: keep only Koshary Large (60)', N'dbo.Remove_From_Cart 9, 8', 0;
EXEC #T '4.6.i discount capped at the subtotal', N'dbo.Checkout_Cart 9, 8, ''Cash'', NULL', 0;
EXEC #V '4.6.i only the fee is paid', N'SELECT CONCAT(discount_amount, ''/'', total_amount) FROM dbo.Orders WHERE order_id = 9', '60.00/20.00';
GO
EXEC #Reset;
EXEC #T '4.6.i setup: remove the unavailable Feteer', N'dbo.Remove_From_Cart 14, 4', 0;
EXEC #T '4.6.i setup: add Koshary Small (40)', N'dbo.Add_To_Cart 14, 2, 1, NULL', 0;
EXEC #T '4.6.i setup: 35 off for Nour', N'dbo.Issue_Voucher 22, ''NOUR35'', 0, 35, ''2030-12-31'', 2', 0;
EXEC #T '4.6.i wallet exactly equal to the total (40 + 20 - 35 = 25)', N'dbo.Checkout_Cart 14, 8, ''Wallet'', NULL', 0;
EXEC #V '4.6.i wallet emptied', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 22', '0.00';
GO
EXEC #Reset;
EXEC #T '4.6.i wallet too low (100 < 140)', N'dbo.Checkout_Cart 13, NULL, ''Wallet'', NULL', -7;
EXEC #T '4.6.i own valid card', N'dbo.Checkout_Cart 13, NULL, ''Card'', 4', 0;
EXEC #V '4.6.i rejected checkout used no order id', N'SELECT CONCAT(o.order_id, ''/'', o.zone_id, ''/'', p.method, ''/'', p.amount, ''/'', p.card_id, ''/'', d.rider_id) FROM dbo.Orders o JOIN dbo.Payment p ON p.order_id = o.order_id JOIN dbo.SubOrder s ON s.order_id = o.order_id JOIN dbo.Delivery d ON d.suborder_id = s.suborder_id WHERE o.cart_id = 13', '9/3/Card/140.00/4/16';
EXEC #V '4.6.i card payment leaves the wallet alone', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 20', '100.00';
GO
EXEC #Reset;
EXEC #T '4.7.a setup: rider 12 unavailable', N'dbo.Set_Rider_Availability 12, 0', 0;
EXEC #T '4.7.a setup: rider 13 unavailable', N'dbo.Set_Rider_Availability 13, 0', 0;
EXEC #T '4.6.i no available rider in Maadi', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', -8;
EXEC #T '4.7.a setup: rider 14 available', N'dbo.Set_Rider_Availability 14, 1', 0;
EXEC #T '4.6.i the only available rider gets everything', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #V '4.6.i riders', N'SELECT STRING_AGG(CAST(d.rider_id AS VARCHAR(10)), '','') FROM dbo.Delivery d JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id WHERE s.order_id = 9', '14,14';
GO
EXEC #Reset;
EXEC #T '4.6.i setup: discount after the product was carted', N'dbo.Set_Product_Promotion 1, 10.00', 0;
EXEC #T '4.6.i prices are taken at checkout', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #V '4.6.i 50 + 90 + 2 x 20', N'SELECT CONCAT((SELECT unit_price FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 1), ''/'', total_amount) FROM dbo.Orders WHERE order_id = 9', '50.00/180.00';
GO
EXEC #Reset;
EXEC #T '4.6.i setup: deactivate a carted product', N'dbo.Toggle_Product_Status 8, 0', 0;
EXEC #T '4.6.i product deactivated after it was carted', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', -4;
EXEC #T '4.6.i Card without a card', N'dbo.Checkout_Cart 11, NULL, ''Card'', 99', -7;
EXEC #T '4.6.i blacklisted customer', N'dbo.Checkout_Cart 12, NULL, ''Cash'', NULL', -3;
DECLARE @o TIME = DATEADD(MINUTE, 90, CAST(GETDATE() AS TIME)), @cl TIME = DATEADD(MINUTE, 180, CAST(GETDATE() AS TIME));
EXEC dbo.Update_Business_Info 4, @o, @cl, NULL, NULL;
EXEC #T '4.6.i business closed right now', N'dbo.Checkout_Cart 11, NULL, ''Cash'', NULL', -4;
DECLARE @o2 TIME = DATEADD(MINUTE, -90, CAST(GETDATE() AS TIME)), @c2 TIME = DATEADD(MINUTE, 90, CAST(GETDATE() AS TIME));
EXEC dbo.Update_Business_Info 4, @o2, @c2, NULL, NULL;
EXEC #T '4.6.i business open right now', N'dbo.Checkout_Cart 11, NULL, ''Cash'', NULL', 0;
GO
EXEC #Reset;
EXEC #T '4.6.i unknown payment method', N'dbo.Checkout_Cart 9, NULL, ''Bitcoin'', NULL', -1;
EXEC #T '4.6.i lower-case payment method', N'dbo.Checkout_Cart 9, NULL, ''cash'', NULL', 0;
EXEC #V '4.6.i method stored exactly as in Section 2.3', N'SELECT CASE WHEN method = ''Cash'' COLLATE Latin1_General_CS_AS THEN ''exact'' ELSE method END FROM dbo.Payment WHERE order_id = 9', 'exact';
GO

/* =============================== 4.6 Cancel, reorder, history, favorites =============================== */
EXEC #Reset;
EXEC #T '4.6.j setup: checkout with WELCOME50 from the wallet', N'dbo.Checkout_Cart 9, 3, ''Wallet'', NULL', 0;
EXEC #T '4.6.j cancel right away', N'dbo.Cancel_Order 9', 0;
EXEC #V '4.6.j everything undone', N'SELECT CONCAT(o.status, ''/'', ISNULL(CAST(o.voucher_id AS VARCHAR(10)), ''NULL''), ''/'', p.refunded_amount, ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17), ''/'', (SELECT status FROM dbo.Voucher WHERE voucher_id = 3), ''/'', (SELECT STRING_AGG(status, '','') FROM dbo.SubOrder WHERE order_id = 9)) FROM dbo.Orders o JOIN dbo.Payment p ON p.order_id = o.order_id WHERE o.order_id = 9', 'Cancelled/NULL/140.00/500.00/Unused/Cancelled,Cancelled';
EXEC #V '4.6.j voucher active again', N'SELECT COUNT(*) FROM dbo.ActiveVouchers WHERE voucher_id = 3', '1';
EXEC #V '4.6.j no longer an active delivery', N'SELECT COUNT(*) FROM dbo.My_Active_Deliveries(12) WHERE order_id = 9', '0';
EXEC #T '4.6.j cancel twice', N'dbo.Cancel_Order 9', -4;
EXEC #T '4.6.j In Progress order', N'dbo.Cancel_Order 6', -4;
EXEC #T '4.6.j Delivered order', N'dbo.Cancel_Order 2', -4;
EXEC #V '4.8.b totals reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #T '4.6.j setup: checkout by card', N'dbo.Checkout_Cart 9, NULL, ''Card'', 1', 0;
EXEC #T '4.6.j card refund goes to the wallet', N'dbo.Cancel_Order 9', 0;
EXEC #V '4.6.j wallet 500 + 190', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17', '690.00';
EXEC #T '4.7.c setup: pick up order 8', N'dbo.Mark_Picked_Up 12', 0;
EXEC #T '4.6.j order picked up', N'dbo.Cancel_Order 8', -4;
GO
EXEC #Reset;
EXEC #T '4.6.k setup: another Zamalek address for Omar', N'dbo.Add_Customer_Address 19, ''Zamalek Flat 2'', 2', 0;
EXEC #T '4.6.k reorder to it', N'dbo.Reorder 3, 13', 0;
EXEC #V '4.6.k quantities and notes copied, no price', N'SELECT STRING_AGG(CONCAT(product_id, '':'', quantity, '':'', notes, '':'', ISNULL(CAST(unit_price AS VARCHAR(10)), ''NULL'')), '','') WITHIN GROUP (ORDER BY product_id) FROM dbo.CartItem WHERE cart_id = 16', '11:1::NULL,12:2:No onions:NULL';
EXEC #V '4.6.k new cart', N'SELECT CONCAT(status, ''/'', customer_id, ''/'', address_id) FROM dbo.Cart WHERE cart_id = 16', 'Active/19/13';
EXEC #T '4.6.k twice to the same address', N'dbo.Reorder 3, 13', -2;
EXEC #T '4.6.k address of another customer', N'dbo.Reorder 3, 1', -3;
EXEC #T '4.6.k order that does not exist', N'dbo.Reorder 99, 13', -1;
GO
EXEC #Reset;
EXEC #T '4.6.k setup: lift the blacklist of Youssef', N'dbo.Lift_Customer_Blacklist 21, 2', 0;
EXEC #T '4.6.k setup: new Maadi address', N'dbo.Add_Customer_Address 21, ''New Maadi Flat'', 1', 0;
EXEC #T '4.6.k reorder a cancelled order', N'dbo.Reorder 4, 13', 0;
EXEC #V '4.6.k items', N'SELECT STRING_AGG(CONCAT(product_id, '':'', quantity), '','') FROM dbo.CartItem WHERE cart_id = 16', '7:1';
GO
EXEC #Reset;
EXEC #V '4.6.n customer without orders', N'SELECT COUNT(*) FROM dbo.My_Order_History(23)', '0';
EXEC #V '4.6.n two orders', N'SELECT STRING_AGG(CONCAT(order_id, ''/'', status, ''/'', number_of_suborders, ''/'', payment_method), '','') WITHIN GROUP (ORDER BY order_id) FROM dbo.My_Order_History(18)', '2/Delivered/2/Wallet,7/Placed/1/Cash';
EXEC #T '4.6 setup: cancel order 8', N'dbo.Cancel_Order 8', 0;
EXEC #V '4.6.n cancelled order with its refund', N'SELECT CONCAT(status, ''/'', discount_amount, ''/'', total_amount, ''/'', refunded_amount) FROM dbo.My_Order_History(22)', 'Cancelled/15.00/155.00/155.00';
EXEC #T '4.6.o favorite an unavailable product', N'dbo.Toggle_Favorite 17, 4, ''Product''', 0;
EXEC #V '4.6.p unavailable product is not orderable', N'SELECT STRING_AGG(CONCAT(product_id, '':'', is_orderable), '','') WITHIN GROUP (ORDER BY product_id) FROM dbo.My_Favorites(17)', '4:0,5:1';
EXEC #T '4.6.o lower-case item type', N'dbo.Toggle_Favorite 23, 1, ''business''', 0;
EXEC #V '4.6.o added', N'SELECT COUNT(*) FROM dbo.Favorite_Business WHERE customer_id = 23', '1';
EXEC #V '4.6.p business favorites are not listed', N'SELECT COUNT(*) FROM dbo.My_Favorites(23)', '0';
EXEC #T '4.6.o NULL item type', N'dbo.Toggle_Favorite 23, 1, NULL', -1;
EXEC #V '4.6.q only unseen products of ordered categories', N'SELECT STRING_AGG(CONCAT(product_id, '':'', category, '':'', final_price), '','') FROM dbo.Recommended_Products(18)', '7:Desserts:70.00';
EXEC #V '4.6.q customer without orders', N'SELECT COUNT(*) FROM dbo.Recommended_Products(23)', '0';
GO
-- Cancelled orders stay in the tables but don't count as ordered (TA, 2026-11-19).
EXEC #Reset;
EXEC #T '4.6.q setup: Sara orders Tiramisu', N'dbo.Add_To_Cart 10, 7, 1, NULL', 0;
EXEC #T '4.6.q setup: checkout', N'dbo.Checkout_Cart 10, NULL, ''Cash'', NULL', 0;
EXEC #V '4.6.q an ordered product is not recommended', N'SELECT COUNT(*) FROM dbo.Recommended_Products(18)', '0';
EXEC #T '4.6.q setup: cancel that order', N'dbo.Cancel_Order 9', 0;
EXEC #V '4.6.q a product of a cancelled order is recommended again', N'SELECT STRING_AGG(CONCAT(product_id, '':'', category, '':'', final_price), '','') FROM dbo.Recommended_Products(18)', '7:Desserts:70.00';
EXEC #T '4.6.q setup: lift the blacklist of Youssef', N'dbo.Lift_Customer_Blacklist 21, 2', 0;
EXEC #V '4.6.q only a cancelled order: no ordered category', N'SELECT COUNT(*) FROM dbo.Recommended_Products(21)', '0';
GO

/* =============================== 4.7 Rider =============================== */
EXEC #Reset;
EXEC #T '4.7.a NULL rider', N'dbo.Set_Rider_Availability NULL, 1', -1;
EXEC #T '4.7.a NULL flag', N'dbo.Set_Rider_Availability 12, NULL', -1;
EXEC #V '4.7.b two assigned deliveries', N'SELECT STRING_AGG(CAST(delivery_id AS VARCHAR(10)), '','') WITHIN GROUP (ORDER BY delivery_id) FROM dbo.My_Active_Deliveries(13)', '10,12';
EXEC #V '4.7.b rider without deliveries', N'SELECT COUNT(*) FROM dbo.My_Active_Deliveries(14)', '0';
EXEC #V '4.7.e another rider', N'SELECT CONCAT(completed_deliveries, ''/'', total_delivery_fees, ''/'', total_earnings) FROM dbo.My_Earnings(16, ''2026-09-01'', ''2026-09-30'')', '1/30.00/24.00';
EXEC #V '4.7.e rider without deliveries', N'SELECT CONCAT(completed_deliveries, ''/'', total_delivery_fees, ''/'', total_earnings) FROM dbo.My_Earnings(14, ''2026-09-01'', ''2026-09-30'')', '0/0.00/0.00';
EXEC #V '4.7.f one rating', N'SELECT CONCAT(avg_rating, ''/'', ratings_count, ''/'', five_star, ''/'', four_star) FROM dbo.My_Rating_Summary(13)', '4.00/1/0/1';
EXEC #V '4.7.f no ratings', N'SELECT CONCAT(ISNULL(CAST(avg_rating AS VARCHAR(10)), ''NULL''), ''/'', ratings_count) FROM dbo.My_Rating_Summary(14)', 'NULL/0';
EXEC #V '4.7.g Delivered only in the range', N'SELECT STRING_AGG(CAST(delivery_id AS VARCHAR(10)), '','') WITHIN GROUP (ORDER BY delivery_id) FROM dbo.My_Delivery_History(13, ''2026-09-01'', ''2026-09-30'')', '2,4';
EXEC #T '4.7.c last SubOrder of order 7 picked up', N'dbo.Mark_Picked_Up 11', 0;
EXEC #T '4.7.d and delivered', N'dbo.Mark_Delivered 11', 0;
EXEC #V '4.7.d order 7 Delivered', N'SELECT status FROM dbo.Orders WHERE order_id = 7', 'Delivered';
EXEC #T '4.6.l feedback on it', N'dbo.Submit_Feedback 11, ''Good'', NULL, 1', 0;
EXEC #T '4.6.m rate its rider', N'dbo.Rate_Rider 11, 3', 0;
EXEC #V '4.2.f rider 12 with the new rating', N'SELECT CONCAT(completed_deliveries, ''/'', avg_rating) FROM dbo.RiderPerformanceSummary WHERE rider_id = 12', '3/4.00';
EXEC #V '4.8.d low rating today', N'SELECT low_ratings_today FROM dbo.Platform_Health_Snapshot()', '1';
EXEC #V '4.8.d delivered today has a time', N'SELECT CASE WHEN avg_delivery_time_today IS NOT NULL THEN 1 ELSE 0 END FROM dbo.Platform_Health_Snapshot()', '1';
GO
EXEC #Reset;
EXEC #T '4.7 setup: suspension cancels SubOrder 10 of order 6', N'dbo.Suspend_Business 3, 1, ''Audit''', 0;
EXEC #T '4.7.d the remaining SubOrder delivered', N'dbo.Mark_Delivered 9', 0;
EXEC #V '4.7.d Delivered despite the cancelled SubOrder', N'SELECT status FROM dbo.Orders WHERE order_id = 6', 'Delivered';
EXEC #V '4.7.g cancelled delivery listed', N'SELECT STRING_AGG(CONCAT(delivery_id, '':'', status), '','') WITHIN GROUP (ORDER BY delivery_id) FROM dbo.My_Delivery_History(13, ''2026-09-01'', ''2026-09-30'')', '2:Delivered,4:Delivered,10:Cancelled';
EXEC #V '4.8.d one fewer Active business', N'SELECT active_businesses FROM dbo.Platform_Health_Snapshot()', '4';
GO

/* =============================== 4.8 System =============================== */
EXEC #Reset;
EXEC #V '4.8.a exact, starts with, contains', N'SELECT CONCAT((SELECT priority FROM dbo.Search_Platform(17, ''Koshary El Tahrir'')), (SELECT priority FROM dbo.Search_Platform(17, ''Koshary'')), (SELECT priority FROM dbo.Search_Platform(17, ''Tahrir'')))', '123';
EXEC #V '4.8.a mixed priorities', N'SELECT STRING_AGG(CONCAT(business_id, '':'', priority), '','') WITHIN GROUP (ORDER BY priority, business_id) FROM dbo.Search_Platform(17, ''P'')', '2:2,3:3';
EXEC #V '4.8.a other zone, suspended business hidden', N'SELECT STRING_AGG(CONCAT(business_id, '':'', priority), '','') FROM dbo.Search_Platform(20, ''r'')', '7:3';
EXEC #V '4.8.a customer without an address', N'SELECT COUNT(*) FROM dbo.Search_Platform(999, ''a'')', '0';
EXEC #V '4.8.c same zone', N'SELECT STRING_AGG(CONCAT(business_id, '':'', same_zone, '':'', zone_avg_delivery_time), '','') FROM dbo.Nearby_Businesses_By_Category(6, ''Grill'')', '7:1:40.00';
EXEC #V '4.8.c other zone only', N'SELECT STRING_AGG(CONCAT(business_id, '':'', same_zone, '':'', zone_avg_delivery_time), '','') FROM dbo.Nearby_Businesses_By_Category(5, ''Painkillers'')', '3:0:22.50';
EXEC #T '4.8.c setup: Panadol unavailable', N'dbo.Toggle_Product_Status 8, 0', 0;
EXEC #V '4.8.c no available product left in the category', N'SELECT COUNT(*) FROM dbo.Nearby_Businesses_By_Category(5, ''Painkillers'')', '0';
EXEC #T '4.8.d setup: rider 12 unavailable', N'dbo.Set_Rider_Availability 12, 0', 0;
EXEC #V '4.8.d available riders', N'SELECT available_riders FROM dbo.Platform_Health_Snapshot()', '3';
GO

/* =============================== Path tests =============================== */
EXEC #Reset;
EXEC #T 'P1 partner registers', N'dbo.Partner_Register ''Hany'', NULL, ''Saleh'', ''hany.saleh'', ''Pass@030'', ''hany.saleh@mail.com'', ''01000000030'', NULL', 0;
EXEC #T 'P1 business in Zamalek', N'dbo.Register_Business 25, ''Hany Grill'', ''Kebab'', NULL, 2, ''00:00'', ''00:00'', 30, ''02200000030'', ''Restaurant'', ''Egyptian'', ''Grills'', NULL', 0;
EXEC #T 'P1 product', N'dbo.Upsert_Product 9, NULL, ''Kebab Plate'', NULL, ''Grill'', 100.00, 1', 0;
EXEC #T 'P1 cannot be carted while Pending', N'dbo.Add_To_Cart 11, 21, 2, NULL', -4;
EXEC #T 'P1 Zone Admin of Zamalek approves', N'dbo.Approve_Business 9, 3', 0;
EXEC #T 'P1 customer adds it', N'dbo.Add_To_Cart 11, 21, 2, ''Well done''', 0;
EXEC #T 'P1 promotion before checkout', N'dbo.Set_Product_Promotion 21, 20.00', 0;
EXEC #T 'P1 checkout (50 + 2 x 80 + 2 x 25)', N'dbo.Checkout_Cart 11, NULL, ''Cash'', NULL', 0;
EXEC #V 'P1 order', N'SELECT CONCAT(order_id, ''/'', total_amount, ''/'', status) FROM dbo.Orders WHERE cart_id = 11', '9/260.00/Placed';
EXEC #V 'P1 both SubOrders to the only Zamalek rider', N'SELECT STRING_AGG(CONCAT(s.suborder_id, '':'', s.business_id, '':'', d.delivery_id, '':'', d.rider_id), '','') WITHIN GROUP (ORDER BY s.suborder_id) FROM dbo.SubOrder s JOIN dbo.Delivery d ON d.suborder_id = s.suborder_id WHERE s.order_id = 9', '13:4:13:15,14:9:14:15';
EXEC #T 'P1 pick up the grill SubOrder', N'dbo.Mark_Picked_Up 14', 0;
EXEC #V 'P1 order In Progress', N'SELECT status FROM dbo.Orders WHERE order_id = 9', 'In Progress';
EXEC #T 'P1 cannot cancel now', N'dbo.Cancel_Order 9', -4;
EXEC #T 'P1 deliver it', N'dbo.Mark_Delivered 14', 0;
EXEC #T 'P1 pick up the sushi SubOrder', N'dbo.Mark_Picked_Up 13', 0;
EXEC #T 'P1 deliver it', N'dbo.Mark_Delivered 13', 0;
EXEC #V 'P1 order Delivered', N'SELECT status FROM dbo.Orders WHERE order_id = 9', 'Delivered';
EXEC #T 'P1 feedback', N'dbo.Submit_Feedback 14, ''Tasty'', NULL, 2', 0;
EXEC #V 'P1 business rating', N'SELECT CONCAT(avg_rating, ''/'', ratings_count) FROM dbo.BusinessRatingsSummary WHERE business_id = 9', '2.00/1';
EXEC #V 'P1 sold today', N'SELECT STRING_AGG(CONCAT(product_id, '':'', units_sold, '':'', revenue_per_product), '','') FROM dbo.BusinessSalesReport(9, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE))', '21:2:160.00';
EXEC #V 'P1 daily revenue today', N'SELECT STRING_AGG(CONCAT(zone_name, ''/'', business_type, ''/'', number_of_suborders, ''/'', gross_sales, ''/'', delivery_fees, ''/'', platform_commission), '','') FROM dbo.Daily_Revenue_Report(CAST(GETDATE() AS DATE))', 'Zamalek/Restaurant/2/210.00/50.00/21.00';
EXEC #V 'P1 zone report today', N'SELECT CONCAT(number_of_orders, ''/'', avg_order_total, ''/'', platform_commission) FROM dbo.ZoneOrderReport(2, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE))', '1/260.00/21.00';
EXEC #V 'P1 rider earnings today', N'SELECT CONCAT(completed_deliveries, ''/'', total_delivery_fees, ''/'', total_earnings) FROM dbo.My_Earnings(15, CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE))', '2/50.00/40.00';
EXEC #V 'P1 top rider today', N'SELECT STRING_AGG(CONCAT(rider_rank, '':'', rider_id, '':'', completed_delivery_count), '','') FROM dbo.TopRiders(CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE))', '1:15:2';
EXEC #V 'P1 in the top sellers', N'SELECT units_sold FROM dbo.TopSellingProducts WHERE product_id = 21', '2';
EXEC #V 'P1 totals reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0';
GO
EXEC #Reset;
EXEC #T 'P2 rejected partner registers again in Maadi', N'dbo.Register_Business 24, ''Nile Sweets'', ''Back again'', NULL, 1, ''00:00'', ''00:00'', 25, ''02200000024'', ''Restaurant'', ''Egyptian'', ''Desserts'', NULL', 0;
EXEC #V 'P2 hidden while Pending', N'SELECT COUNT(*) FROM dbo.Search_Platform(17, ''Nile'')', '0';
EXEC #T 'P2 Zone Admin of Maadi approves', N'dbo.Approve_Business 8, 2', 0;
EXEC #V 'P2 found by search', N'SELECT CONCAT(business_id, '':'', priority) FROM dbo.Search_Platform(17, ''Nile'')', '8:2';
EXEC #V 'P2 listed near Maadi for Desserts', N'SELECT COUNT(*) FROM dbo.Nearby_Businesses_By_Category(1, ''Desserts'')', '4';
EXEC #T 'P2 its Konafa can be carted', N'dbo.Add_To_Cart 9, 20, 1, NULL', 0;
EXEC #T 'P2 and checked out', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #V 'P2 three SubOrders', N'SELECT COUNT(*) FROM dbo.SubOrder WHERE order_id = 9', '3';
GO

/* =============================== 4.1 Drop and clear (destructive, last) =============================== */
EXEC #Reset;
EXEC #T '4.1.e clearAllTables', N'dbo.clearAllTables', 0;
EXEC #V '4.1.e no rows left', N'SELECT (SELECT COUNT(*) FROM dbo.Feedback) + (SELECT COUNT(*) FROM dbo.Payment) + (SELECT COUNT(*) FROM dbo.Delivery)
	+ (SELECT COUNT(*) FROM dbo.SubOrder) + (SELECT COUNT(*) FROM dbo.Orders) + (SELECT COUNT(*) FROM dbo.CartItem) + (SELECT COUNT(*) FROM dbo.Cart)
	+ (SELECT COUNT(*) FROM dbo.Voucher) + (SELECT COUNT(*) FROM dbo.Favorite_Product) + (SELECT COUNT(*) FROM dbo.Favorite_Business)
	+ (SELECT COUNT(*) FROM dbo.Product) + (SELECT COUNT(*) FROM dbo.Blacklist) + (SELECT COUNT(*) FROM dbo.Pharmacy) + (SELECT COUNT(*) FROM dbo.Restaurant)
	+ (SELECT COUNT(*) FROM dbo.Business_Phone) + (SELECT COUNT(*) FROM dbo.Business) + (SELECT COUNT(*) FROM dbo.Card) + (SELECT COUNT(*) FROM dbo.Address)
	+ (SELECT COUNT(*) FROM dbo.Customer) + (SELECT COUNT(*) FROM dbo.Rider) + (SELECT COUNT(*) FROM dbo.Partner) + (SELECT COUNT(*) FROM dbo.Admin)
	+ (SELECT COUNT(*) FROM dbo.User_Phone) + (SELECT COUNT(*) FROM dbo.Users) + (SELECT COUNT(*) FROM dbo.Zone)', '0';
EXEC #T '4.1.e clearAllTables on empty tables', N'dbo.clearAllTables', 0;
EXEC #Exec '4.1.e insert after clearing', N'INSERT INTO dbo.Zone (zone_name, delivery_fee) VALUES (''Z'', 1); INSERT INTO dbo.Users (first_name, last_name, username, password, email) VALUES (''A'', ''B'', ''ab'', ''p'', ''ab@mail.com'');';
EXEC #V '4.1.e identities restart at 1', N'SELECT CONCAT((SELECT zone_id FROM dbo.Zone), ''/'', (SELECT user_id FROM dbo.Users))', '1/1';
EXEC #T '4.1.c dropAllTables', N'dbo.dropAllTables', 0;
EXEC #V '4.1.c no tables left', N'SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(''dbo'')', '0';
EXEC #T '4.1.b createAllTables again', N'dbo.createAllTables', 0;
EXEC #V '4.1.b 25 tables', N'SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(''dbo'')', '25';
EXEC #Exec '4.1.b seed data fits the rebuilt tables', N'EXEC #Reset;';
EXEC #V '4.2 views still work on the rebuilt tables', N'SELECT COUNT(*) FROM dbo.allBusinessProfiles', '8';
EXEC #T '4.1.d dropAllProceduresFunctionsViews', N'dbo.dropAllProceduresFunctionsViews', 0;
EXEC #V '4.1.d only itself is left', N'SELECT STRING_AGG(name, '','') FROM sys.objects WHERE type IN (''P'', ''FN'', ''IF'', ''TF'', ''V'') AND is_ms_shipped = 0', 'dropAllProceduresFunctionsViews';
EXEC #V '4.1.d tables kept', N'SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(''dbo'')', '25';
GO

/* =============================== Report =============================== */
DECLARE @passed INT = (SELECT COUNT(*) FROM #R WHERE ok = 1), @total INT = (SELECT COUNT(*) FROM #R);
PRINT CONCAT('Passed ', @passed, ' of ', @total, ' checks. Run Team_28.sql again to rebuild the procedures, functions and views.');
GO
