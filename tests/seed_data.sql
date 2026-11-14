/* =====================================================================================
   SEED DATA, Databases I, Winter 2026, Milestone 2
   Run this file once after EXEC createAllTables (all tables must be empty).
   ===================================================================================== */
-- Replace XX with your team number, or select your database in the toolbar and delete this line.
USE LocalDeliveryMarketplace_Team_XX;
GO
SET NOCOUNT ON;
GO
IF EXISTS (SELECT 1 FROM dbo.Zone) OR EXISTS (SELECT 1 FROM dbo.Users)
BEGIN
    PRINT '*** The tables are not empty. Run EXEC clearAllTables first, then run this file again. ***';
    SET NOEXEC ON;
END
GO
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
PRINT 'Seed data loaded.';
GO
SET NOEXEC OFF;
GO
