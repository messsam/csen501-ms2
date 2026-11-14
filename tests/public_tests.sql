/* =====================================================================================
   PUBLIC TESTS
   Databases I, Winter 2026, Milestone 2
   HOW TO RUN: put grader.py, this file and your Team_XX.sql in one folder and run
       python grader.py Team_XX.sql
   (see the guide). It prints which tests passed and which failed.
   WARNING: the tests delete the rows of your tables and load the seed data.
   How it works: every test reloads the seed data first, then calls your objects and
   compares the results with the expected values. A rejection test passes only if your
   object returns the expected error code (-1 .. -9, or 0 / an empty result for the
   functions) AND leaves every table unchanged. All helper objects are
   temporary (#name) and nothing is added to your database.
   Results: two result grids at the end (one row per test, then a summary).
   ===================================================================================== */
-- 1) Replace XX with your team number, or select your database in the toolbar and delete this line.
USE LocalDeliveryMarketplace_Team_XX;
GO
SET NOCOUNT ON;
GO
/* Safety check: run only inside a LocalDeliveryMarketplace_Team_XX database. */
IF DB_NAME() NOT LIKE 'LocalDeliveryMarketplace[_]Team[_]%'
BEGIN
    DECLARE @found NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(name AS NVARCHAR(MAX)), N', ') FROM sys.databases
                                    WHERE name LIKE 'LocalDeliveryMarketplace[_]Team[_]%');
    PRINT '*** Wrong database (' + DB_NAME() + '). Replace XX in the USE line at the top with your team number and run again. ***';
    PRINT '*** Databases found on this server: ' + ISNULL(@found, 'none. Run your Team_XX.sql file first.') + ' ***';
    SET NOEXEC ON;
END
GO
/* If the tables do not exist yet, build them with your own createAllTables procedure. */
IF OBJECT_ID('dbo.Zone', 'U') IS NULL AND OBJECT_ID('dbo.createAllTables', 'P') IS NOT NULL
BEGIN
    PRINT 'Your tables were missing, so the tests ran EXEC createAllTables first.';
    EXEC dbo.createAllTables;
END
GO
IF OBJECT_ID('dbo.Zone', 'U') IS NULL
BEGIN
    PRINT '*** The table Zone does not exist and there is no createAllTables procedure. Run your Team_XX.sql file first. ***';
    SET NOEXEC ON;
END
GO
/* ------------------------------ Test harness (temporary objects only) ------------------------------ */
IF OBJECT_ID('tempdb..#TestResults') IS NOT NULL DROP TABLE #TestResults;
IF OBJECT_ID('tempdb..#Current') IS NOT NULL DROP TABLE #Current;
IF OBJECT_ID('tempdb..#Out') IS NOT NULL DROP TABLE #Out;
IF OBJECT_ID('tempdb..#exp') IS NOT NULL DROP TABLE #exp;
IF OBJECT_ID('tempdb..#Last') IS NOT NULL DROP TABLE #Last;
CREATE TABLE #TestResults (
    seq         INT IDENTITY(1,1),
    test_id     VARCHAR(30),
    kind        VARCHAR(10),
    description NVARCHAR(300),
    fail_count  INT NOT NULL DEFAULT 0,
    finished    BIT NOT NULL DEFAULT 0,
    details     NVARCHAR(MAX) NOT NULL DEFAULT N''
);
CREATE TABLE #Current (test_id VARCHAR(30));
CREATE TABLE #Out (v NVARCHAR(4000));
CREATE TABLE #Last (rc INT, ok BIT);
GO
IF OBJECT_ID('tempdb..#Fail') IS NOT NULL DROP PROCEDURE #Fail;
IF OBJECT_ID('tempdb..#DbState') IS NOT NULL DROP PROCEDURE #DbState;
IF OBJECT_ID('tempdb..#Exec') IS NOT NULL DROP PROCEDURE #Exec;
IF OBJECT_ID('tempdb..#Reject') IS NOT NULL DROP PROCEDURE #Reject;
IF OBJECT_ID('tempdb..#Rc') IS NOT NULL DROP PROCEDURE #Rc;
IF OBJECT_ID('tempdb..#Eq') IS NOT NULL DROP PROCEDURE #Eq;
IF OBJECT_ID('tempdb..#Rows') IS NOT NULL DROP PROCEDURE #Rows;
IF OBJECT_ID('tempdb..#Cols') IS NOT NULL DROP PROCEDURE #Cols;
IF OBJECT_ID('tempdb..#Begin') IS NOT NULL DROP PROCEDURE #Begin;
IF OBJECT_ID('tempdb..#End') IS NOT NULL DROP PROCEDURE #End;
IF OBJECT_ID('tempdb..#ResetData') IS NOT NULL DROP PROCEDURE #ResetData;
IF OBJECT_ID('tempdb..#SeedData') IS NOT NULL DROP PROCEDURE #SeedData;
GO
/* Records a failure for the running test. */
CREATE PROCEDURE #Fail @msg NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE #TestResults
    SET fail_count = fail_count + 1,
        details = details + CASE WHEN details = N'' THEN N'' ELSE N' || ' END + @msg
    WHERE test_id = (SELECT TOP 1 test_id FROM #Current);
END
GO
/* Fingerprint of every table (row count and checksum) used to prove that a rejected call changed nothing. */
CREATE PROCEDURE #DbState @state NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX) = N'SELECT @s = CONCAT(N'''', N''tables:''';
    SELECT @sql = @sql + N', N''' + t.name + N':'', (SELECT CONCAT(COUNT_BIG(*), N''/'', CHECKSUM_AGG(BINARY_CHECKSUM(*))) FROM dbo.'
                       + QUOTENAME(t.name) + N'), N'';'''
    FROM sys.tables t
    WHERE t.schema_id = SCHEMA_ID('dbo')
    ORDER BY t.name;
    SET @sql = @sql + N')';
    EXEC sp_executesql @sql, N'@s NVARCHAR(MAX) OUTPUT', @state OUTPUT;
END
GO
/* Runs a statement that must succeed. */
CREATE PROCEDURE #Exec @sql NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        DECLARE @m NVARCHAR(MAX) = N'Unexpected error in [' + LEFT(@sql, 200) + N']: ' + ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK;
        EXEC #Fail @m;
        RETURN;
    END CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
        DECLARE @m2 NVARCHAR(MAX) = N'The call left a transaction open: ' + LEFT(@sql, 200);
        EXEC #Fail @m2;
    END
END
GO
/* Runs a raw SQL statement that must fail with an error (for example a constraint violation) and leave every table unchanged. */
CREATE PROCEDURE #Reject @sql NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @before NVARCHAR(MAX), @after NVARCHAR(MAX), @err BIT = 0, @m NVARCHAR(MAX), @errno INT, @errmsg NVARCHAR(4000);
    EXEC #DbState @before OUTPUT;
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SET @err = 1;
        SELECT @errno = ERROR_NUMBER(), @errmsg = ERROR_MESSAGE();
    END CATCH
    /* A missing object or a wrong parameter list is not a valid rejection. */
    IF @errno IN (201, 207, 208, 2809, 2812, 4121, 8144, 8145)
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @m = N'The call could not run (missing object or wrong parameters) [' + LEFT(@sql, 200) + N']: ' + @errmsg;
        EXEC #Fail @m;
        RETURN;
    END
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
        SET @m = N'The rejected call left a transaction open: ' + LEFT(@sql, 200);
        EXEC #Fail @m;
    END
    IF @err = 0
    BEGIN
        SET @m = N'Expected the call to be rejected with an error, but it succeeded: ' + LEFT(@sql, 200);
        EXEC #Fail @m;
    END
    EXEC #DbState @after OUTPUT;
    IF @before <> @after
    BEGIN
        SET @m = N'The rejected call changed the database: ' + LEFT(@sql, 200);
        EXEC #Fail @m;
    END
END
GO
/* Calls a stored procedure and checks the integer it returns (0 = success, negative = error code of Section 2.4).
   @call is the call without "EXEC": procedure name followed by its arguments. An OUTPUT bit may be passed as @ok.
   A call with a negative expected code must also leave every table unchanged. The returned code and @ok are kept in #Last. */
CREATE PROCEDURE #Rc @label NVARCHAR(200), @call NVARCHAR(MAX), @expected INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @before NVARCHAR(MAX), @after NVARCHAR(MAX), @rc INT = NULL, @ok BIT = NULL, @q NVARCHAR(MAX),
            @m NVARCHAR(MAX), @errno INT = NULL, @errmsg NVARCHAR(4000);
    EXEC #DbState @before OUTPUT;
    SET @q = N'EXEC @rc = ' + @call;
    BEGIN TRY
        EXEC sp_executesql @q, N'@rc INT OUTPUT, @ok BIT OUTPUT', @rc OUTPUT, @ok OUTPUT;
    END TRY
    BEGIN CATCH
        SELECT @errno = ERROR_NUMBER(), @errmsg = ERROR_MESSAGE();
    END CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK;
        SET @m = @label + N': the call left a transaction open: ' + LEFT(@call, 200);
        EXEC #Fail @m;
    END
    DELETE FROM #Last;
    INSERT INTO #Last VALUES (@rc, @ok);
    IF @errno IS NOT NULL
    BEGIN
        SET @m = @label + N': the call raised an error instead of returning ' + CAST(@expected AS NVARCHAR(10))
               + N' [' + LEFT(@call, 200) + N']: ' + @errmsg;
        EXEC #Fail @m;
        RETURN;
    END
    IF ISNULL(@rc, 999) <> @expected
    BEGIN
        SET @m = @label + N': expected return code ' + CAST(@expected AS NVARCHAR(10)) + N' but got '
               + ISNULL(CAST(@rc AS NVARCHAR(10)), N'NULL') + N' [' + LEFT(@call, 200) + N']';
        EXEC #Fail @m;
    END
    IF @expected <> 0
    BEGIN
        EXEC #DbState @after OUTPUT;
        IF @before <> @after
        BEGIN
            SET @m = @label + N': the rejected call changed the database [' + LEFT(@call, 200) + N']';
            EXEC #Fail @m;
        END
    END
END
GO
/* Compares one scalar value (the query must return a single value) with the expected value, after converting both to @type. */
CREATE PROCEDURE #Eq @label NVARCHAR(200), @query NVARCHAR(MAX), @expected NVARCHAR(4000), @type NVARCHAR(50) = N'NVARCHAR(4000)'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @got NVARCHAR(4000), @exp NVARCHAR(4000), @m NVARCHAR(MAX), @q NVARCHAR(MAX);
    BEGIN TRY
        SET @q = N'SELECT @v = CONVERT(NVARCHAR(4000), CONVERT(' + @type + N', (' + @query + N')))';
        EXEC sp_executesql @q, N'@v NVARCHAR(4000) OUTPUT', @got OUTPUT;
        SET @q = N'SELECT @v = CONVERT(NVARCHAR(4000), CONVERT(' + @type + N', @x))';
        EXEC sp_executesql @q, N'@x NVARCHAR(4000), @v NVARCHAR(4000) OUTPUT', @expected, @exp OUTPUT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @m = @label + N': error while evaluating [' + LEFT(@query, 200) + N']: ' + ERROR_MESSAGE();
        EXEC #Fail @m;
        RETURN;
    END CATCH
    IF ISNULL(@got, N'<NULL>') <> ISNULL(@exp, N'<NULL>')
    BEGIN
        SET @m = @label + N': expected ' + ISNULL(@exp, N'NULL') + N' but got ' + ISNULL(@got, N'NULL');
        EXEC #Fail @m;
    END
END
GO
/* Compares the rows returned by @query with the rows of #exp (same column order and types; order of rows is ignored). */
CREATE PROCEDURE #Rows @label NVARCHAR(200), @query NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @m NVARCHAR(MAX), @ne INT, @na INT, @missing NVARCHAR(MAX), @extra NVARCHAR(MAX);
    IF OBJECT_ID('tempdb..#exp') IS NULL
    BEGIN
        EXEC #Fail N'Harness error: #exp is missing.';
        RETURN;
    END
    SELECT TOP 0 * INTO #act FROM #exp;
    BEGIN TRY
        INSERT INTO #act EXEC sp_executesql @query;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @m = @label + N': error while running [' + LEFT(@query, 200) + N']: ' + ERROR_MESSAGE();
        EXEC #Fail @m;
        RETURN;
    END CATCH
    SELECT @ne = COUNT(*) FROM #exp;
    SELECT @na = COUNT(*) FROM #act;
    SET @missing = (SELECT * FROM (SELECT * FROM #exp EXCEPT SELECT * FROM #act) x FOR JSON PATH, INCLUDE_NULL_VALUES);
    SET @extra   = (SELECT * FROM (SELECT * FROM #act EXCEPT SELECT * FROM #exp) x FOR JSON PATH, INCLUDE_NULL_VALUES);
    IF @ne <> @na OR @missing IS NOT NULL OR @extra IS NOT NULL
    BEGIN
        SET @m = @label + N': expected ' + CAST(@ne AS NVARCHAR(10)) + N' row(s), got ' + CAST(@na AS NVARCHAR(10))
               + N'. Missing rows: ' + ISNULL(@missing, N'none') + N'. Unexpected rows: ' + ISNULL(@extra, N'none');
        EXEC #Fail @m;
    END
END
GO
/* Checks the names and order of the columns returned by @query. */
CREATE PROCEDURE #Cols @label NVARCHAR(200), @query NVARCHAR(MAX), @expected NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @got NVARCHAR(MAX), @err NVARCHAR(4000), @m NVARCHAR(MAX);
    SELECT TOP 1 @err = error_message
    FROM sys.dm_exec_describe_first_result_set(@query, NULL, 0)
    WHERE error_number IS NOT NULL;
    IF @err IS NOT NULL
    BEGIN
        SET @m = @label + N': cannot describe [' + LEFT(@query, 200) + N']: ' + @err;
        EXEC #Fail @m;
        RETURN;
    END
    SELECT @got = STRING_AGG(CAST(name AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY column_ordinal)
    FROM sys.dm_exec_describe_first_result_set(@query, NULL, 0)
    WHERE is_hidden = 0;
    IF ISNULL(@got, N'') <> REPLACE(@expected, N' ', N'')
    BEGIN
        SET @m = @label + N': expected columns (' + @expected + N') but got (' + ISNULL(@got, N'none') + N')';
        EXEC #Fail @m;
    END
END
GO
/* Starts a test: registers it and reloads the seed data. */
CREATE PROCEDURE #Begin @id VARCHAR(30), @kind VARCHAR(10), @description NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;
    IF @@TRANCOUNT > 0 ROLLBACK;
    DELETE FROM #Current;
    INSERT INTO #Current VALUES (@id);
    INSERT INTO #TestResults (test_id, kind, description) VALUES (@id, @kind, @description);
    DELETE FROM #Out;
    BEGIN TRY
        EXEC #ResetData;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @m NVARCHAR(MAX) = N'Could not reload the seed data (check your table and column names): ' + ERROR_MESSAGE();
        EXEC #Fail @m;
    END CATCH
END
GO
/* Ends a test. A test that never reaches #End is reported as stopped early. */
CREATE PROCEDURE #End
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE #TestResults SET finished = 1 WHERE test_id = (SELECT TOP 1 test_id FROM #Current);
END
GO
/* Deletes every row, resets identities and reloads the seed data. */
CREATE PROCEDURE #ResetData
AS
BEGIN
    SET NOCOUNT ON;
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
    DECLARE @sql NVARCHAR(MAX) = N'';
    SELECT @sql = @sql + N'DBCC CHECKIDENT (''dbo.' + OBJECT_NAME(ic.object_id) + N''', RESEED, 0) WITH NO_INFOMSGS; '
    FROM sys.identity_columns ic
    JOIN sys.tables t ON t.object_id = ic.object_id
    WHERE ic.last_value IS NOT NULL AND t.schema_id = SCHEMA_ID('dbo');
    EXEC sp_executesql @sql;
    EXEC #SeedData;
END
GO
CREATE PROCEDURE #SeedData
AS
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
/* =====================================================================================
   PUBLIC TESTS: unit tests (one requirement at a time) and path tests (sequences)
   Procedures are checked by their return code (Section 2.4): 0 on success, a negative code on error.
   A call that must be rejected must also leave every table unchanged.
   ===================================================================================== */

/* ------------------------------------ 4.1 ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.1.a', 'Unit', 'Database name follows LocalDeliveryMarketplace_Team_XX';
EXEC #Eq 'database name', N'SELECT CASE WHEN DB_NAME() LIKE ''LocalDeliveryMarketplace[_]Team[_]%'' THEN 1 ELSE 0 END', '1', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.1.b', 'Unit', 'createAllTables: tables, column order, types, NULL-ability, primary keys and identities match Section 3';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (table_name SYSNAME, column_position INT, column_name SYSNAME, data_type VARCHAR(30), is_nullable VARCHAR(3));
INSERT INTO #exp VALUES
        ('Zone', 1, 'zone_id', 'int', 'NO'),
        ('Zone', 2, 'zone_name', 'varchar(50)', 'NO'),
        ('Zone', 3, 'delivery_fee', 'decimal(10,2)', 'NO'),
        ('Users', 1, 'user_id', 'int', 'NO'),
        ('Users', 2, 'first_name', 'varchar(30)', 'NO'),
        ('Users', 3, 'middle_name', 'varchar(30)', 'YES'),
        ('Users', 4, 'last_name', 'varchar(30)', 'NO'),
        ('Users', 5, 'username', 'varchar(30)', 'NO'),
        ('Users', 6, 'password', 'varchar(30)', 'NO'),
        ('Users', 7, 'email', 'varchar(100)', 'NO'),
        ('Users', 8, 'dob', 'date', 'YES'),
        ('Users', 9, 'account_status', 'varchar(20)', 'NO'),
        ('User_Phone', 1, 'user_id', 'int', 'NO'),
        ('User_Phone', 2, 'phone', 'char(11)', 'NO'),
        ('Admin', 1, 'admin_id', 'int', 'NO'),
        ('Admin', 2, 'role', 'varchar(20)', 'NO'),
        ('Admin', 3, 'zone_id', 'int', 'YES'),
        ('Partner', 1, 'partner_id', 'int', 'NO'),
        ('Rider', 1, 'rider_id', 'int', 'NO'),
        ('Rider', 2, 'vehicle_type', 'varchar(30)', 'NO'),
        ('Rider', 3, 'plate_no', 'varchar(15)', 'NO'),
        ('Rider', 4, 'license_no', 'varchar(20)', 'NO'),
        ('Rider', 5, 'is_available', 'bit', 'NO'),
        ('Rider', 6, 'zone_id', 'int', 'NO'),
        ('Customer', 1, 'customer_id', 'int', 'NO'),
        ('Customer', 2, 'wallet_balance', 'decimal(10,2)', 'NO'),
        ('Address', 1, 'address_id', 'int', 'NO'),
        ('Address', 2, 'description', 'varchar(150)', 'NO'),
        ('Address', 3, 'is_active', 'bit', 'NO'),
        ('Address', 4, 'customer_id', 'int', 'NO'),
        ('Address', 5, 'zone_id', 'int', 'NO'),
        ('Card', 1, 'card_id', 'int', 'NO'),
        ('Card', 2, 'card_no', 'char(16)', 'NO'),
        ('Card', 3, 'card_holder_name', 'varchar(100)', 'NO'),
        ('Card', 4, 'expiration_date', 'date', 'NO'),
        ('Card', 5, 'customer_id', 'int', 'NO'),
        ('Business', 1, 'business_id', 'int', 'NO'),
        ('Business', 2, 'name', 'varchar(100)', 'NO'),
        ('Business', 3, 'description', 'varchar(255)', 'YES'),
        ('Business', 4, 'link_website', 'varchar(255)', 'YES'),
        ('Business', 5, 'opening_hour', 'time', 'NO'),
        ('Business', 6, 'closing_hour', 'time', 'NO'),
        ('Business', 7, 'expected_delivery_time', 'int', 'NO'),
        ('Business', 8, 'status', 'varchar(20)', 'NO'),
        ('Business', 9, 'suspension_reason', 'varchar(255)', 'YES'),
        ('Business', 10, 'partner_id', 'int', 'NO'),
        ('Business', 11, 'zone_id', 'int', 'NO'),
        ('Business_Phone', 1, 'business_id', 'int', 'NO'),
        ('Business_Phone', 2, 'phone', 'char(11)', 'NO'),
        ('Restaurant', 1, 'business_id', 'int', 'NO'),
        ('Restaurant', 2, 'cuisine_type', 'varchar(50)', 'NO'),
        ('Restaurant', 3, 'food_category', 'varchar(50)', 'NO'),
        ('Pharmacy', 1, 'business_id', 'int', 'NO'),
        ('Pharmacy', 2, 'pharmacy_type', 'varchar(50)', 'NO'),
        ('Blacklist', 1, 'customer_id', 'int', 'NO'),
        ('Blacklist', 2, 'admin_id', 'int', 'NO'),
        ('Blacklist', 3, 'reason', 'varchar(255)', 'NO'),
        ('Product', 1, 'product_id', 'int', 'NO'),
        ('Product', 2, 'name', 'varchar(100)', 'NO'),
        ('Product', 3, 'description', 'varchar(255)', 'YES'),
        ('Product', 4, 'category', 'varchar(50)', 'NO'),
        ('Product', 5, 'price', 'decimal(10,2)', 'NO'),
        ('Product', 6, 'discount_amount', 'decimal(10,2)', 'NO'),
        ('Product', 7, 'is_available', 'bit', 'NO'),
        ('Product', 8, 'business_id', 'int', 'NO'),
        ('Favorite_Business', 1, 'customer_id', 'int', 'NO'),
        ('Favorite_Business', 2, 'business_id', 'int', 'NO'),
        ('Favorite_Product', 1, 'customer_id', 'int', 'NO'),
        ('Favorite_Product', 2, 'product_id', 'int', 'NO'),
        ('Voucher', 1, 'voucher_id', 'int', 'NO'),
        ('Voucher', 2, 'promo_code', 'varchar(30)', 'NO'),
        ('Voucher', 3, 'is_percentage', 'bit', 'NO'),
        ('Voucher', 4, 'amount', 'decimal(10,2)', 'NO'),
        ('Voucher', 5, 'expiry_date', 'date', 'NO'),
        ('Voucher', 6, 'status', 'varchar(20)', 'NO'),
        ('Voucher', 7, 'customer_id', 'int', 'NO'),
        ('Cart', 1, 'cart_id', 'int', 'NO'),
        ('Cart', 2, 'status', 'varchar(20)', 'NO'),
        ('Cart', 3, 'created_at', 'datetime', 'NO'),
        ('Cart', 4, 'customer_id', 'int', 'NO'),
        ('Cart', 5, 'address_id', 'int', 'NO'),
        ('CartItem', 1, 'cart_id', 'int', 'NO'),
        ('CartItem', 2, 'product_id', 'int', 'NO'),
        ('CartItem', 3, 'quantity', 'int', 'NO'),
        ('CartItem', 4, 'notes', 'varchar(255)', 'YES'),
        ('CartItem', 5, 'unit_price', 'decimal(10,2)', 'YES'),
        ('Orders', 1, 'order_id', 'int', 'NO'),
        ('Orders', 2, 'order_date', 'datetime', 'NO'),
        ('Orders', 3, 'status', 'varchar(20)', 'NO'),
        ('Orders', 4, 'discount_amount', 'decimal(10,2)', 'NO'),
        ('Orders', 5, 'total_amount', 'decimal(10,2)', 'NO'),
        ('Orders', 6, 'cart_id', 'int', 'NO'),
        ('Orders', 7, 'zone_id', 'int', 'NO'),
        ('Orders', 8, 'voucher_id', 'int', 'YES'),
        ('SubOrder', 1, 'suborder_id', 'int', 'NO'),
        ('SubOrder', 2, 'status', 'varchar(20)', 'NO'),
        ('SubOrder', 3, 'total_price', 'decimal(10,2)', 'NO'),
        ('SubOrder', 4, 'delivery_fee', 'decimal(10,2)', 'NO'),
        ('SubOrder', 5, 'order_id', 'int', 'NO'),
        ('SubOrder', 6, 'business_id', 'int', 'NO'),
        ('Delivery', 1, 'delivery_id', 'int', 'NO'),
        ('Delivery', 2, 'assigned_at', 'datetime', 'NO'),
        ('Delivery', 3, 'picked_up_at', 'datetime', 'YES'),
        ('Delivery', 4, 'delivered_at', 'datetime', 'YES'),
        ('Delivery', 5, 'tracking_time', 'int', 'YES'),
        ('Delivery', 6, 'rider_rating', 'int', 'YES'),
        ('Delivery', 7, 'suborder_id', 'int', 'NO'),
        ('Delivery', 8, 'rider_id', 'int', 'NO'),
        ('Payment', 1, 'payment_id', 'int', 'NO'),
        ('Payment', 2, 'amount', 'decimal(10,2)', 'NO'),
        ('Payment', 3, 'currency', 'varchar(3)', 'NO'),
        ('Payment', 4, 'method', 'varchar(20)', 'NO'),
        ('Payment', 5, 'transaction_date', 'datetime', 'NO'),
        ('Payment', 6, 'refunded_amount', 'decimal(10,2)', 'NO'),
        ('Payment', 7, 'order_id', 'int', 'NO'),
        ('Payment', 8, 'card_id', 'int', 'YES'),
        ('Feedback', 1, 'feedback_id', 'int', 'NO'),
        ('Feedback', 2, 'headline', 'varchar(100)', 'NO'),
        ('Feedback', 3, 'description', 'varchar(500)', 'YES'),
        ('Feedback', 4, 'rating', 'int', 'NO'),
        ('Feedback', 5, 'feedback_date', 'datetime', 'NO'),
        ('Feedback', 6, 'suborder_id', 'int', 'NO');
EXEC #Rows 'columns', N'
    SELECT c.TABLE_NAME, ROW_NUMBER() OVER (PARTITION BY c.TABLE_NAME ORDER BY c.ORDINAL_POSITION), c.COLUMN_NAME,
           CASE WHEN c.DATA_TYPE IN (''varchar'', ''char'') THEN c.DATA_TYPE + ''('' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + '')''
                WHEN c.DATA_TYPE = ''decimal'' THEN ''decimal('' + CAST(c.NUMERIC_PRECISION AS VARCHAR(10)) + '','' + CAST(c.NUMERIC_SCALE AS VARCHAR(10)) + '')''
                ELSE c.DATA_TYPE END,
           c.IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS c
    JOIN INFORMATION_SCHEMA.TABLES t ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
    WHERE t.TABLE_TYPE = ''BASE TABLE'' AND t.TABLE_SCHEMA = ''dbo''';
GO
DROP TABLE IF EXISTS #exp;
GO
CREATE TABLE #exp (table_name SYSNAME, column_name SYSNAME);
INSERT INTO #exp VALUES ('Zone', 'zone_id'), ('Users', 'user_id'), ('User_Phone', 'user_id'), ('User_Phone', 'phone'), ('Admin', 'admin_id'), ('Partner', 'partner_id'), ('Rider', 'rider_id'), ('Customer', 'customer_id'),
    ('Address', 'address_id'), ('Card', 'card_id'), ('Business', 'business_id'), ('Business_Phone', 'business_id'), ('Business_Phone', 'phone'), ('Restaurant', 'business_id'), ('Pharmacy', 'business_id'),
    ('Blacklist', 'customer_id'), ('Product', 'product_id'), ('Favorite_Business', 'customer_id'), ('Favorite_Business', 'business_id'), ('Favorite_Product', 'customer_id'), ('Favorite_Product', 'product_id'),
    ('Voucher', 'voucher_id'), ('Cart', 'cart_id'), ('CartItem', 'cart_id'), ('CartItem', 'product_id'), ('Orders', 'order_id'), ('SubOrder', 'suborder_id'), ('Delivery', 'delivery_id'),
    ('Payment', 'payment_id'), ('Feedback', 'feedback_id');
EXEC #Rows 'primary keys', N'
    SELECT k.TABLE_NAME, k.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE k ON k.CONSTRAINT_NAME = tc.CONSTRAINT_NAME AND k.TABLE_NAME = tc.TABLE_NAME
    WHERE tc.CONSTRAINT_TYPE = ''PRIMARY KEY'' AND tc.TABLE_SCHEMA = ''dbo''';
DELETE FROM #exp;
INSERT INTO #exp VALUES ('Zone', 'zone_id'), ('Users', 'user_id'), ('Address', 'address_id'), ('Card', 'card_id'), ('Business', 'business_id'), ('Product', 'product_id'), ('Voucher', 'voucher_id'),
    ('Cart', 'cart_id'), ('Orders', 'order_id'), ('SubOrder', 'suborder_id'), ('Delivery', 'delivery_id'), ('Payment', 'payment_id'), ('Feedback', 'feedback_id');
EXEC #Rows 'identity columns', N'
    SELECT OBJECT_NAME(ic.object_id), ic.name
    FROM sys.identity_columns ic JOIN sys.tables t ON t.object_id = ic.object_id
    WHERE t.schema_id = SCHEMA_ID(''dbo'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.1.e', 'Unit', 'clearAllTables empties every table and restarts identities at 1';
EXEC #Rc 'clearAllTables', N'dbo.clearAllTables', 0;
EXEC #Eq 'rows left in all tables', N'SELECT (SELECT COUNT(*) FROM dbo.Feedback) + (SELECT COUNT(*) FROM dbo.Payment) + (SELECT COUNT(*) FROM dbo.Delivery) + (SELECT COUNT(*) FROM dbo.SubOrder) + (SELECT COUNT(*) FROM dbo.Orders) + (SELECT COUNT(*) FROM dbo.CartItem) + (SELECT COUNT(*) FROM dbo.Cart) + (SELECT COUNT(*) FROM dbo.Voucher) + (SELECT COUNT(*) FROM dbo.Favorite_Product) + (SELECT COUNT(*) FROM dbo.Favorite_Business) + (SELECT COUNT(*) FROM dbo.Product) + (SELECT COUNT(*) FROM dbo.Blacklist) + (SELECT COUNT(*) FROM dbo.Pharmacy) + (SELECT COUNT(*) FROM dbo.Restaurant) + (SELECT COUNT(*) FROM dbo.Business_Phone) + (SELECT COUNT(*) FROM dbo.Business) + (SELECT COUNT(*) FROM dbo.Card) + (SELECT COUNT(*) FROM dbo.Address) + (SELECT COUNT(*) FROM dbo.Customer) + (SELECT COUNT(*) FROM dbo.Rider) + (SELECT COUNT(*) FROM dbo.Partner) + (SELECT COUNT(*) FROM dbo.Admin) + (SELECT COUNT(*) FROM dbo.User_Phone) + (SELECT COUNT(*) FROM dbo.Users) + (SELECT COUNT(*) FROM dbo.Zone)', '0', 'INT';
EXEC #Exec N'INSERT INTO dbo.Zone (zone_name, delivery_fee) VALUES (''Test Zone'', 10);';
EXEC #Eq 'first zone_id after clearing', N'SELECT zone_id FROM dbo.Zone WHERE zone_name = ''Test Zone''', '1', 'INT';
EXEC #Exec N'INSERT INTO dbo.Users (first_name, last_name, username, password, email) VALUES (''A'', ''B'', ''ab'', ''p'', ''ab@mail.com'');';
EXEC #Eq 'first user_id after clearing', N'SELECT user_id FROM dbo.Users WHERE username = ''ab''', '1', 'INT';
EXEC #End;
GO

/* ------------------------------------ 4.2 Views ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.a', 'Unit', 'allBusinessProfiles lists every business (any status) with type, zone and partner';
EXEC #Cols 'columns', N'SELECT * FROM dbo.allBusinessProfiles', 'business_id,business_name,business_type,zone_name,partner_name,status,opening_hour,closing_hour';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, business_name VARCHAR(100), business_type VARCHAR(20), zone_name VARCHAR(50), partner_name VARCHAR(101), status VARCHAR(20), opening_hour TIME, closing_hour TIME);
INSERT INTO #exp VALUES
    (1, 'Koshary El Tahrir', 'Restaurant', 'Maadi',     'Tarek Fouad',   'Active',    '00:00', '00:00'),
    (2, 'Pizza Roma',        'Restaurant', 'Maadi',     'Laura Bianchi', 'Active',    '00:00', '00:00'),
    (3, 'Seif Pharmacy',     'Pharmacy',   'Maadi',     'Seif Mahmoud',  'Active',    '00:00', '00:00'),
    (4, 'Sushi Zen',         'Restaurant', 'Zamalek',   'Kenji Sato',    'Active',    '00:00', '00:00'),
    (5, 'Zamalek Pharmacy',  'Pharmacy',   'Zamalek',   'Dina Fathy',    'Pending',   '09:00', '21:00'),
    (6, 'Sweet Corner',      'Restaurant', 'New Cairo', 'Rania Ezz',     'Suspended', '10:00', '02:00'),
    (7, 'Cairo Grill',       'Restaurant', 'New Cairo', 'Hassan Gaber',  'Active',    '00:00', '00:00'),
    (8, 'Nile Sweets',       'Restaurant', 'New Cairo', 'Nabil Fares',   'Rejected',  '10:00', '23:00');
EXEC #Rows 'rows', N'SELECT * FROM dbo.allBusinessProfiles';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.b', 'Unit', 'BusinessesPerZone counts Active businesses and keeps empty zones';
EXEC #Cols 'columns', N'SELECT * FROM dbo.BusinessesPerZone', 'zone_id,zone_name,business_count';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (zone_id INT, zone_name VARCHAR(50), business_count INT);
INSERT INTO #exp VALUES (1, 'Maadi', 3), (2, 'Zamalek', 1), (3, 'New Cairo', 1), (4, 'Heliopolis', 0);
EXEC #Rows 'rows', N'SELECT * FROM dbo.BusinessesPerZone';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.c', 'Unit', 'BusinessRatingsSummary averages feedback per business';
EXEC #Cols 'columns', N'SELECT * FROM dbo.BusinessRatingsSummary', 'business_id,business_name,avg_rating,ratings_count';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, business_name VARCHAR(100), avg_rating DECIMAL(10,2), ratings_count INT);
INSERT INTO #exp VALUES
    (1, 'Koshary El Tahrir', 3.50, 2), (2, 'Pizza Roma', NULL, 0), (3, 'Seif Pharmacy', 4.00, 1),
    (4, 'Sushi Zen', 5.00, 1), (5, 'Zamalek Pharmacy', NULL, 0), (6, 'Sweet Corner', NULL, 0),
    (7, 'Cairo Grill', 4.00, 1), (8, 'Nile Sweets', NULL, 0);
EXEC #Rows 'rows', N'SELECT * FROM dbo.BusinessRatingsSummary';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.d', 'Unit', 'ActiveVouchers returns Unused, non-expired vouchers';
EXEC #Cols 'columns', N'SELECT * FROM dbo.ActiveVouchers', 'voucher_id,promo_code,customer_id,is_percentage,amount,expiry_date';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (voucher_id INT, promo_code VARCHAR(30), customer_id INT, is_percentage BIT, amount DECIMAL(10,2), expiry_date DATE);
INSERT INTO #exp VALUES (3, 'WELCOME50', 17, 0, 50.00, '2030-12-31'), (4, 'SAVE10', 17, 1, 10.00, '2030-12-31'), (7, 'SARA25', 18, 1, 25.00, '2030-12-31');
EXEC #Rows 'rows', N'SELECT * FROM dbo.ActiveVouchers';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.e', 'Unit', 'PendingBusinessApprovals returns Pending businesses only';
EXEC #Cols 'columns', N'SELECT * FROM dbo.PendingBusinessApprovals', 'business_id,business_name,business_type,zone_name,partner_name';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, business_name VARCHAR(100), business_type VARCHAR(20), zone_name VARCHAR(50), partner_name VARCHAR(101));
INSERT INTO #exp VALUES (5, 'Zamalek Pharmacy', 'Pharmacy', 'Zamalek', 'Dina Fathy');
EXEC #Rows 'rows', N'SELECT * FROM dbo.PendingBusinessApprovals';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.f', 'Unit', 'RiderPerformanceSummary lists every rider with completed deliveries and rating';
EXEC #Cols 'columns', N'SELECT * FROM dbo.RiderPerformanceSummary', 'rider_id,rider_name,zone_name,completed_deliveries,avg_rating';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (rider_id INT, rider_name VARCHAR(101), zone_name VARCHAR(50), completed_deliveries INT, avg_rating DECIMAL(10,2));
INSERT INTO #exp VALUES
    (12, 'Ali Ibrahim', 'Maadi', 2, 4.50), (13, 'Mostafa Kamal', 'Maadi', 2, 4.00), (14, 'Yehia Saad', 'Maadi', 0, NULL),
    (15, 'Ziad Nabil', 'Zamalek', 1, 5.00), (16, 'Fady Ramzy', 'New Cairo', 1, 3.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.RiderPerformanceSummary';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.g', 'Unit', 'TopSellingProducts returns the top 10 by units, ignoring cancelled SubOrders';
EXEC #Cols 'columns', N'SELECT * FROM dbo.TopSellingProducts', 'product_id,product_name,business_name,business_type,units_sold,total_revenue';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (product_id INT, product_name VARCHAR(100), business_name VARCHAR(100), business_type VARCHAR(20), units_sold INT, total_revenue DECIMAL(10,2));
INSERT INTO #exp VALUES
    (2, 'Koshary Small', 'Koshary El Tahrir', 'Restaurant', 3, 120.00),
    (1, 'Koshary Large', 'Koshary El Tahrir', 'Restaurant', 2, 120.00),
    (3, 'Rice Pudding', 'Koshary El Tahrir', 'Restaurant', 2, 40.00),
    (8, 'Panadol Extra', 'Seif Pharmacy', 'Pharmacy', 2, 90.00),
    (12, 'Miso Soup', 'Sushi Zen', 'Restaurant', 2, 100.00),
    (5, 'Margherita Pizza', 'Pizza Roma', 'Restaurant', 1, 100.00),
    (6, 'Pepperoni Pizza', 'Pizza Roma', 'Restaurant', 1, 150.00),
    (9, 'Vitamin C', 'Seif Pharmacy', 'Pharmacy', 1, 80.00),
    (10, 'Hand Sanitizer', 'Seif Pharmacy', 'Pharmacy', 1, 30.00),
    (11, 'Salmon Roll', 'Sushi Zen', 'Restaurant', 1, 180.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.TopSellingProducts';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.2.h', 'Unit', 'ZoneDeliveryPerformance counts Delivered deliveries per zone';
EXEC #Cols 'columns', N'SELECT * FROM dbo.ZoneDeliveryPerformance', 'zone_id,zone_name,delivery_count,avg_tracking_time';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (zone_id INT, zone_name VARCHAR(50), delivery_count INT, avg_tracking_time DECIMAL(10,2));
INSERT INTO #exp VALUES (1, 'Maadi', 4, 22.50), (2, 'Zamalek', 1, 35.00), (3, 'New Cairo', 1, 40.00), (4, 'Heliopolis', 0, NULL);
EXEC #Rows 'rows', N'SELECT * FROM dbo.ZoneDeliveryPerformance';
EXEC #End;
GO

/* ------------------------------------ 4.3 Accounts ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.a-1', 'Unit', 'Customer_Register creates an Active customer with a 0 wallet and a phone';
EXEC #Rc 'register', N'dbo.Customer_Register ''Mariam'', NULL, ''Wael'', ''mariam.wael'', ''Pass@025'', ''mariam.wael@mail.com'', ''01000000025'', ''2001-05-05''', 0;
EXEC #Eq 'status', N'SELECT account_status FROM dbo.Users WHERE username = ''mariam.wael''', 'Active';
EXEC #Eq 'wallet', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = (SELECT user_id FROM dbo.Users WHERE username = ''mariam.wael'')', '0.00', 'DECIMAL(10,2)';
EXEC #Eq 'phone', N'SELECT phone FROM dbo.User_Phone WHERE user_id = (SELECT user_id FROM dbo.Users WHERE username = ''mariam.wael'')', '01000000025';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.a-2', 'Unit', 'Customer_Register returns -2 for a duplicate username and -1 for an invalid phone';
EXEC #Rc 'duplicate username', N'dbo.Customer_Register ''Mariam'', NULL, ''Wael'', ''ahmed.salem'', ''Pass@025'', ''mariam.wael@mail.com'', ''01000000025'', ''2001-05-05''', -2;
EXEC #Rc 'invalid phone', N'dbo.Customer_Register ''Mariam'', NULL, ''Wael'', ''mariam.wael'', ''Pass@025'', ''mariam.wael@mail.com'', ''0100'', ''2001-05-05''', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.b-1', 'Unit', 'Partner_Register creates a partner without a business';
EXEC #Rc 'register', N'dbo.Partner_Register ''Omar'', NULL, ''Fawzy'', ''omar.fawzy'', ''Pass@025'', ''omar.fawzy@mail.com'', ''01000000025'', ''1988-08-08''', 0;
EXEC #Eq 'partner row', N'SELECT COUNT(*) FROM dbo.Partner WHERE partner_id = (SELECT user_id FROM dbo.Users WHERE username = ''omar.fawzy'')', '1', 'INT';
EXEC #Eq 'no business', N'SELECT COUNT(*) FROM dbo.Business WHERE partner_id = (SELECT user_id FROM dbo.Users WHERE username = ''omar.fawzy'')', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.b-2', 'Unit', 'Partner_Register returns -2 for a duplicate email';
EXEC #Rc 'duplicate email', N'dbo.Partner_Register ''Omar'', NULL, ''Fawzy'', ''omar.fawzy'', ''Pass@025'', ''tarek.fouad@mail.com'', ''01000000025'', ''1988-08-08''', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.c-1', 'Unit', 'Rider_Register creates an available rider in the given zone';
EXEC #Rc 'register', N'dbo.Rider_Register ''Hady'', NULL, ''Wagdy'', ''hady.wagdy'', ''Pass@025'', ''hady.wagdy@mail.com'', ''01000000025'', ''1997-03-03'', ''Motorcycle'', ''MAA-9999'', ''LIC-9999'', 2', 0;
EXEC #Eq 'rider', N'SELECT CONCAT(vehicle_type, ''/'', plate_no, ''/'', license_no, ''/'', is_available, ''/'', zone_id) FROM dbo.Rider WHERE rider_id = (SELECT user_id FROM dbo.Users WHERE username = ''hady.wagdy'')', 'Motorcycle/MAA-9999/LIC-9999/1/2';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.c-2', 'Unit', 'Rider_Register returns -2 for a duplicate plate number';
EXEC #Rc 'duplicate plate', N'dbo.Rider_Register ''Hady'', NULL, ''Wagdy'', ''hady.wagdy'', ''Pass@025'', ''hady.wagdy@mail.com'', ''01000000025'', ''1997-03-03'', ''Motorcycle'', ''MAA-1201'', ''LIC-9999'', 2', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.d', 'Unit', 'CustomerLoginValidation accepts valid Active customers only';
EXEC #Eq 'valid', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017'')', '1', 'BIT';
EXEC #Eq 'wrong password', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''wrong'')', '0', 'BIT';
EXEC #Eq 'a partner is not a customer', N'SELECT dbo.CustomerLoginValidation(''tarek.fouad'', ''Pass@004'')', '0', 'BIT';
EXEC #Eq 'blacklisted customer', N'SELECT dbo.CustomerLoginValidation(''youssef.amin'', ''Pass@021'')', '0', 'BIT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.e', 'Unit', 'PartnerLoginValidation accepts partners only';
EXEC #Eq 'valid', N'SELECT dbo.PartnerLoginValidation(''tarek.fouad'', ''Pass@004'')', '1', 'BIT';
EXEC #Eq 'a customer is not a partner', N'SELECT dbo.PartnerLoginValidation(''ahmed.salem'', ''Pass@017'')', '0', 'BIT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.f', 'Unit', 'RiderLoginValidation accepts riders only';
EXEC #Eq 'valid', N'SELECT dbo.RiderLoginValidation(''ali.ibrahim'', ''Pass@012'')', '1', 'BIT';
EXEC #Eq 'a customer is not a rider', N'SELECT dbo.RiderLoginValidation(''ahmed.salem'', ''Pass@017'')', '0', 'BIT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.g', 'Unit', 'AdminLoginValidation accepts admins only';
EXEC #Eq 'super admin', N'SELECT dbo.AdminLoginValidation(''mona.hassan'', ''Pass@001'')', '1', 'BIT';
EXEC #Eq 'a customer is not an admin', N'SELECT dbo.AdminLoginValidation(''ahmed.salem'', ''Pass@017'')', '0', 'BIT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.h-1', 'Unit', 'Change_Password changes the password and sets success = 1';
EXEC #Rc 'change', N'dbo.Change_Password 17, ''Pass@017'', ''New@123'', ''New@123'', @ok OUTPUT', 0;
EXEC #Eq 'success flag', N'SELECT ok FROM #Last', '1', 'BIT';
EXEC #Eq 'new password works', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''New@123'')', '1', 'BIT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.3.h-2', 'Unit', 'Change_Password returns -1 with success = 0 and changes nothing when the repeat differs or the old password is wrong';
EXEC #Rc 'repeat differs', N'dbo.Change_Password 17, ''Pass@017'', ''New@123'', ''Other@123'', @ok OUTPUT', -1;
EXEC #Eq 'success flag', N'SELECT ok FROM #Last', '0', 'BIT';
EXEC #Rc 'wrong old password', N'dbo.Change_Password 17, ''wrong'', ''New@123'', ''New@123'', @ok OUTPUT', -1;
EXEC #Eq 'success flag', N'SELECT ok FROM #Last', '0', 'BIT';
EXEC #Eq 'old password still works', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017'')', '1', 'BIT';
EXEC #End;
GO

/* ------------------------------------ 4.4 Admin ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.a-1', 'Unit', 'Create_Admin: a Super Admin creates a Zone Admin';
EXEC #Rc 'create', N'dbo.Create_Admin ''Laila'', NULL, ''Gamal'', ''laila.gamal'', ''Pass@028'', ''laila.gamal@mail.com'', ''01000000028'', ''1989-09-09'', ''Zone Admin'', 4, 1', 0;
EXEC #Eq 'admin row', N'SELECT CONCAT(role, ''/'', zone_id) FROM dbo.Admin WHERE admin_id = (SELECT user_id FROM dbo.Users WHERE username = ''laila.gamal'')', 'Zone Admin/4';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.a-2', 'Unit', 'Create_Admin returns -3 when a Zone Admin calls it';
EXEC #Rc 'zone admin caller', N'dbo.Create_Admin ''Laila'', NULL, ''Gamal'', ''laila.gamal'', ''Pass@028'', ''laila.gamal@mail.com'', ''01000000028'', ''1989-09-09'', ''Zone Admin'', 4, 2', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.b-1', 'Unit', 'Approve_Business: the Zone Admin of the zone approves a Pending business';
EXEC #Rc 'approve', N'dbo.Approve_Business 5, 3', 0;
EXEC #Eq 'status', N'SELECT status FROM dbo.Business WHERE business_id = 5', 'Active';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.b-2', 'Unit', 'Approve_Business returns -3 for a Zone Admin of another zone and -4 for a business that is not Pending';
EXEC #Rc 'other zone', N'dbo.Approve_Business 5, 2', -3;
EXEC #Rc 'not pending', N'dbo.Approve_Business 1, 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.c-1', 'Unit', 'Reject_Business changes a Pending business to Rejected';
EXEC #Rc 'reject', N'dbo.Reject_Business 5, 1', 0;
EXEC #Eq 'status', N'SELECT status FROM dbo.Business WHERE business_id = 5', 'Rejected';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.c-2', 'Unit', 'Reject_Business returns -3 for a Zone Admin of another zone and -4 for a business that is not Pending';
EXEC #Rc 'other zone', N'dbo.Reject_Business 5, 2', -3;
EXEC #Rc 'not pending', N'dbo.Reject_Business 2, 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.d-1', 'Unit', 'Suspend_Business hides the business, cancels its Placed/Assigned SubOrders and refunds them';
EXEC #Rc 'suspend', N'dbo.Suspend_Business 3, 2, ''Expired medicines''', 0;
EXEC #Eq 'status', N'SELECT CONCAT(status, ''/'', suspension_reason) FROM dbo.Business WHERE business_id = 3', 'Suspended/Expired medicines';
EXEC #Eq 'products hidden', N'SELECT COUNT(*) FROM dbo.Product WHERE business_id = 3 AND is_available = 1', '0', 'INT';
EXEC #Eq 'assigned SubOrders cancelled', N'SELECT STRING_AGG(CONCAT(suborder_id, '':'', status), '','') WITHIN GROUP (ORDER BY suborder_id) FROM dbo.SubOrder WHERE business_id = 3', '3:Delivered,10:Cancelled,11:Cancelled';
EXEC #Eq 'order 7 cancelled entirely', N'SELECT status FROM dbo.Orders WHERE order_id = 7', 'Cancelled';
EXEC #Eq 'order 6 still in progress', N'SELECT status FROM dbo.Orders WHERE order_id = 6', 'In Progress';
EXEC #Eq 'order 7 refund (cash, no wallet)', N'SELECT CONCAT(refunded_amount, ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 18)) FROM dbo.Payment WHERE order_id = 7', '100.00/50.00';
EXEC #Eq 'order 6 refund (card: 30 + 20 fee)', N'SELECT CONCAT(refunded_amount, ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17)) FROM dbo.Payment WHERE order_id = 6', '50.00/550.00';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.d-2', 'Unit', 'Suspend_Business restores the voucher of an order it cancels entirely and caps the refund at the payment';
EXEC #Rc 'suspend', N'dbo.Suspend_Business 2, 1, ''Health inspection''', 0;
EXEC #Eq 'order 8', N'SELECT status FROM dbo.Orders WHERE order_id = 8', 'Cancelled';
EXEC #Eq 'order 8 voucher unlinked', N'SELECT voucher_id FROM dbo.Orders WHERE order_id = 8', NULL, 'INT';
EXEC #Eq 'voucher 5', N'SELECT status FROM dbo.Voucher WHERE voucher_id = 5', 'Unused';
EXEC #Eq 'refund capped at 155 and credited', N'SELECT CONCAT(refunded_amount, ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 22)) FROM dbo.Payment WHERE order_id = 8', '155.00/180.00';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.d-3', 'Unit', 'Suspend_Business returns -3 out of scope and -4 for a business that is not Active';
EXEC #Rc 'zone admin of another zone', N'dbo.Suspend_Business 3, 3, ''Reason''', -3;
EXEC #Rc 'pending business', N'dbo.Suspend_Business 5, 3, ''Reason''', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.e-1', 'Unit', 'Reinstate_Business: a Super Admin reinstates a Suspended business, products stay unavailable';
EXEC #Rc 'reinstate', N'dbo.Reinstate_Business 6, 1', 0;
EXEC #Eq 'status', N'SELECT CONCAT(status, ''/'', ISNULL(suspension_reason, ''<null>'')) FROM dbo.Business WHERE business_id = 6', 'Active/<null>';
EXEC #Eq 'products still hidden', N'SELECT is_available FROM dbo.Product WHERE product_id = 15', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.e-2', 'Unit', 'Reinstate_Business returns -3 for a Zone Admin and -4 for a business that is not Suspended';
EXEC #Rc 'zone admin', N'dbo.Reinstate_Business 6, 2', -3;
EXEC #Rc 'active business', N'dbo.Reinstate_Business 1, 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.f-1', 'Unit', 'Create_Zone creates a zone';
EXEC #Rc 'create', N'dbo.Create_Zone ''Dokki'', 18.00, 1', 0;
EXEC #Eq 'fee', N'SELECT delivery_fee FROM dbo.Zone WHERE zone_name = ''Dokki''', '18.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.f-2', 'Unit', 'Create_Zone returns -2 for a duplicate name, -3 for a Zone Admin and -1 for a negative fee';
EXEC #Rc 'duplicate', N'dbo.Create_Zone ''Maadi'', 18.00, 1', -2;
EXEC #Rc 'zone admin', N'dbo.Create_Zone ''Dokki'', 18.00, 2', -3;
EXEC #Rc 'negative fee', N'dbo.Create_Zone ''Dokki'', -1.00, 1', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.g-1', 'Unit', 'Update_Zone_Fee changes the fee without touching existing SubOrders';
EXEC #Rc 'update', N'dbo.Update_Zone_Fee 1, 22.50, 1', 0;
EXEC #Eq 'fee', N'SELECT delivery_fee FROM dbo.Zone WHERE zone_id = 1', '22.50', 'DECIMAL(10,2)';
EXEC #Eq 'old SubOrder fee', N'SELECT delivery_fee FROM dbo.SubOrder WHERE suborder_id = 1', '20.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.g-2', 'Unit', 'Update_Zone_Fee returns -3 for a Zone Admin and -1 for a negative fee';
EXEC #Rc 'zone admin', N'dbo.Update_Zone_Fee 1, 22.50, 2', -3;
EXEC #Rc 'negative fee', N'dbo.Update_Zone_Fee 1, -5.00, 1', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.h-1', 'Unit', 'Assign_Admin_Zone moves a Zone Admin';
EXEC #Rc 'assign', N'dbo.Assign_Admin_Zone 2, 4, 1', 0;
EXEC #Eq 'zone', N'SELECT zone_id FROM dbo.Admin WHERE admin_id = 2', '4', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.h-2', 'Unit', 'Assign_Admin_Zone returns -1 for a Super Admin target and -3 for a Zone Admin caller';
EXEC #Rc 'super admin target', N'dbo.Assign_Admin_Zone 1, 4, 1', -1;
EXEC #Rc 'zone admin caller', N'dbo.Assign_Admin_Zone 3, 4, 2', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.i-1', 'Unit', 'Issue_Voucher creates an Unused voucher';
EXEC #Rc 'issue', N'dbo.Issue_Voucher 17, ''NEW20'', 0, 20.00, ''2030-12-31'', 1', 0;
EXEC #Eq 'voucher', N'SELECT CONCAT(status, ''/'', amount, ''/'', is_percentage, ''/'', customer_id) FROM dbo.Voucher WHERE promo_code = ''NEW20''', 'Unused/20.00/0/17';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.i-2', 'Unit', 'Issue_Voucher returns -3 for a Blacklisted customer and -2 for a duplicate promo code';
EXEC #Rc 'blacklisted customer', N'dbo.Issue_Voucher 21, ''NEW20'', 0, 20.00, ''2030-12-31'', 1', -3;
EXEC #Rc 'duplicate code', N'dbo.Issue_Voucher 17, ''SAVE10'', 0, 20.00, ''2030-12-31'', 1', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.j-1', 'Unit', 'Blacklist_Customer blocks the account, cancels cancellable orders, refunds and deletes Unused vouchers';
EXEC #Rc 'blacklist', N'dbo.Blacklist_Customer 22, 2, ''Chargeback fraud''', 0;
EXEC #Eq 'account', N'SELECT account_status FROM dbo.Users WHERE user_id = 22', 'Blacklisted';
EXEC #Eq 'blacklist row', N'SELECT CONCAT(admin_id, ''/'', reason) FROM dbo.Blacklist WHERE customer_id = 22', '2/Chargeback fraud';
EXEC #Eq 'order 8 cancelled', N'SELECT status FROM dbo.Orders WHERE order_id = 8', 'Cancelled';
EXEC #Eq 'refund and wallet', N'SELECT CONCAT(refunded_amount, ''/'', (SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 22)) FROM dbo.Payment WHERE order_id = 8', '155.00/180.00';
EXEC #Eq 'vouchers of the customer', N'SELECT COUNT(*) FROM dbo.Voucher WHERE customer_id = 22', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.j-2', 'Unit', 'Blacklist_Customer returns -4 if already Blacklisted and -3 for a Zone Admin without an address in the zone';
EXEC #Rc 'already blacklisted', N'dbo.Blacklist_Customer 21, 1, ''Again''', -4;
EXEC #Rc 'zone admin of another zone', N'dbo.Blacklist_Customer 22, 3, ''Fraud''', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.k-1', 'Unit', 'Lift_Customer_Blacklist: the admin who blacklisted the customer lifts it';
EXEC #Rc 'lift', N'dbo.Lift_Customer_Blacklist 21, 2', 0;
EXEC #Eq 'account', N'SELECT account_status FROM dbo.Users WHERE user_id = 21', 'Active';
EXEC #Eq 'blacklist row removed', N'SELECT COUNT(*) FROM dbo.Blacklist WHERE customer_id = 21', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.k-2', 'Unit', 'Lift_Customer_Blacklist returns -3 for any other admin, even a Super Admin';
EXEC #Rc 'super admin', N'dbo.Lift_Customer_Blacklist 21, 1', -3;
EXEC #Rc 'other zone admin', N'dbo.Lift_Customer_Blacklist 21, 3', -3;
EXEC #Eq 'still blacklisted', N'SELECT account_status FROM dbo.Users WHERE user_id = 21', 'Blacklisted';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.l', 'Unit', 'ZoneOrderReport for Maadi and New Cairo in September';
EXEC #Cols 'columns', N'SELECT * FROM dbo.ZoneOrderReport(1, ''2026-09-01'', ''2026-09-30'')', 'zone_id,zone_name,number_of_orders,avg_order_total,platform_commission';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (zone_id INT, zone_name VARCHAR(50), number_of_orders INT, avg_order_total DECIMAL(10,2), platform_commission DECIMAL(10,2));
INSERT INTO #exp VALUES (1, 'Maadi', 5, 169.00, 73.00);
EXEC #Rows 'Maadi', N'SELECT * FROM dbo.ZoneOrderReport(1, ''2026-09-01'', ''2026-09-30'')';
DELETE FROM #exp;
INSERT INTO #exp VALUES (3, 'New Cairo', 1, 350.00, 22.00);
EXEC #Rows 'New Cairo', N'SELECT * FROM dbo.ZoneOrderReport(3, ''2026-09-01'', ''2026-09-30'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.m', 'Unit', 'TopRiders ranks riders by deliveries delivered in the period';
EXEC #Cols 'columns', N'SELECT * FROM dbo.TopRiders(''2026-09-01'', ''2026-09-30'')', 'rider_rank,rider_id,rider_name,completed_delivery_count';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (rider_rank INT, rider_id INT, rider_name VARCHAR(101), completed_delivery_count INT);
INSERT INTO #exp VALUES (1, 12, 'Ali Ibrahim', 2), (2, 13, 'Mostafa Kamal', 2), (3, 15, 'Ziad Nabil', 1), (4, 16, 'Fady Ramzy', 1);
EXEC #Rows 'rows', N'SELECT * FROM dbo.TopRiders(''2026-09-01'', ''2026-09-30'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.4.n', 'Unit', 'Daily_Revenue_Report splits a day by zone and business type';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Daily_Revenue_Report(''2026-09-02'')', 'zone_name,business_type,number_of_suborders,gross_sales,delivery_fees,platform_commission';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (zone_name VARCHAR(50), business_type VARCHAR(20), number_of_suborders INT, gross_sales DECIMAL(10,2), delivery_fees DECIMAL(10,2), platform_commission DECIMAL(10,2));
INSERT INTO #exp VALUES ('Maadi', 'Pharmacy', 1, 90.00, 20.00, 9.00), ('Maadi', 'Restaurant', 1, 40.00, 20.00, 4.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.Daily_Revenue_Report(''2026-09-02'')';
EXEC #End;
GO

/* ------------------------------------ 4.5 Partner ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.a-1', 'Unit', 'Register_Business creates a Pending restaurant with its phone and subtype row';
EXEC #Rc 'register', N'dbo.Register_Business 11, ''Mai Bakery'', ''Fresh bread'', NULL, 1, ''08:00'', ''23:00'', 25, ''02200000011'', ''Restaurant'', ''Egyptian'', ''Bakery'', NULL', 0;
EXEC #Eq 'business', N'SELECT CONCAT(name, ''/'', status, ''/'', zone_id, ''/'', expected_delivery_time) FROM dbo.Business WHERE partner_id = 11', 'Mai Bakery/Pending/1/25';
EXEC #Eq 'phone', N'SELECT COUNT(*) FROM dbo.Business_Phone bp JOIN dbo.Business b ON b.business_id = bp.business_id WHERE b.partner_id = 11 AND bp.phone = ''02200000011''', '1', 'INT';
EXEC #Eq 'restaurant row', N'SELECT CONCAT(cuisine_type, ''/'', food_category) FROM dbo.Restaurant WHERE business_id = (SELECT business_id FROM dbo.Business WHERE partner_id = 11)', 'Egyptian/Bakery';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.a-2', 'Unit', 'Register_Business returns -2 for a partner who already owns a business and -1 for a Restaurant without food_category';
EXEC #Rc 'already owns a business', N'dbo.Register_Business 4, ''Second'', NULL, NULL, 1, ''08:00'', ''23:00'', 25, ''02200000011'', ''Restaurant'', ''Egyptian'', ''Bakery'', NULL', -2;
EXEC #Rc 'restaurant without category', N'dbo.Register_Business 11, ''Mai Bakery'', NULL, NULL, 1, ''08:00'', ''23:00'', 25, ''02200000011'', ''Restaurant'', ''Egyptian'', NULL, NULL', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.a-3', 'Unit', 'Register_Business re-registers a Rejected business: same row, new data, back to Pending';
EXEC #Rc 'register again', N'dbo.Register_Business 24, ''Nile Pharmacy'', ''Now a pharmacy'', NULL, 3, ''09:00'', ''22:00'', 30, ''02200000088'', ''Pharmacy'', NULL, NULL, ''Retail''', 0;
EXEC #Eq 'same business row', N'SELECT CONCAT(COUNT(*), ''/'', MAX(business_id), ''/'', MAX(status), ''/'', MAX(name)) FROM dbo.Business WHERE partner_id = 24', '1/8/Pending/Nile Pharmacy';
EXEC #Eq 'phones replaced', N'SELECT STRING_AGG(phone, '','') FROM dbo.Business_Phone WHERE business_id = 8', '02200000088';
EXEC #Eq 'subtype replaced', N'SELECT CONCAT((SELECT COUNT(*) FROM dbo.Restaurant WHERE business_id = 8), ''/'', (SELECT COUNT(*) FROM dbo.Pharmacy WHERE business_id = 8))', '0/1';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.b-1', 'Unit', 'Update_Business_Info updates hours and website and adds a phone';
EXEC #Rc 'update', N'dbo.Update_Business_Info 1, ''08:00'', ''22:00'', ''02200000099'', ''www.new.example''', 0;
EXEC #Eq 'hours and website', N'SELECT CONCAT(opening_hour, ''/'', closing_hour, ''/'', link_website) FROM dbo.Business WHERE business_id = 1', '08:00:00.0000000/22:00:00.0000000/www.new.example';
EXEC #Eq 'phones', N'SELECT COUNT(*) FROM dbo.Business_Phone WHERE business_id = 1', '3', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.b-2', 'Unit', 'Update_Business_Info returns -1 for a malformed phone and -2 for a phone the business already has';
EXEC #Rc 'malformed phone', N'dbo.Update_Business_Info 1, ''08:00'', ''22:00'', ''abc'', NULL', -1;
EXEC #Rc 'existing phone', N'dbo.Update_Business_Info 1, ''08:00'', ''22:00'', ''02200000001'', NULL', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.c-1', 'Unit', 'Upsert_Product inserts a new product when product_id is NULL and updates an existing one';
EXEC #Rc 'insert', N'dbo.Upsert_Product 1, NULL, ''Molokhia'', ''Green soup'', ''Main Dishes'', 55.00, 1', 0;
EXEC #Eq 'new product', N'SELECT CONCAT(product_id, ''/'', price, ''/'', discount_amount, ''/'', is_available) FROM dbo.Product WHERE name = ''Molokhia''', '21/55.00/0.00/1';
EXEC #Rc 'update', N'dbo.Upsert_Product 1, 1, ''Koshary Large'', ''Large box'', ''Main Dishes'', 65.00, 1', 0;
EXEC #Eq 'updated price', N'SELECT price FROM dbo.Product WHERE product_id = 1', '65.00', 'DECIMAL(10,2)';
EXEC #Eq 'placed orders keep their price', N'SELECT unit_price FROM dbo.CartItem WHERE cart_id = 1 AND product_id = 1', '60.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.c-2', 'Unit', 'Upsert_Product returns -3 for a product of another business, -4 for a Suspended business and -1 for invalid data';
EXEC #Rc 'not my product', N'dbo.Upsert_Product 1, 5, ''Margherita Pizza'', NULL, ''Pizza'', 120.00, 1', -3;
EXEC #Rc 'suspended business', N'dbo.Upsert_Product 6, NULL, ''New Sweet'', NULL, ''Desserts'', 30.00, 1', -4;
EXEC #Rc 'price zero', N'dbo.Upsert_Product 1, NULL, ''Free'', NULL, ''Main Dishes'', 0.00, 1', -1;
EXEC #Rc 'discount would exceed 50%', N'dbo.Upsert_Product 2, 5, ''Margherita Pizza'', NULL, ''Pizza'', 30.00, 1', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.d-1', 'Unit', 'Toggle_Product_Status deactivates a product';
EXEC #Rc 'deactivate', N'dbo.Toggle_Product_Status 1, 0', 0;
EXEC #Eq 'availability', N'SELECT is_available FROM dbo.Product WHERE product_id = 1', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.d-2', 'Unit', 'Toggle_Product_Status returns -4 when reactivating while the business is Suspended';
EXEC #Rc 'reactivate', N'dbo.Toggle_Product_Status 15, 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.e-1', 'Unit', 'Set_Product_Promotion sets a discount amount and 0 removes it';
EXEC #Rc 'set', N'dbo.Set_Product_Promotion 1, 30.00', 0;
EXEC #Eq 'discount', N'SELECT discount_amount FROM dbo.Product WHERE product_id = 1', '30.00', 'DECIMAL(10,2)';
EXEC #Rc 'remove', N'dbo.Set_Product_Promotion 1, 0', 0;
EXEC #Eq 'removed', N'SELECT discount_amount FROM dbo.Product WHERE product_id = 1', '0.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.e-2', 'Unit', 'Set_Product_Promotion returns -1 for a discount above 50% of the price or a negative one';
EXEC #Rc 'above 50%', N'dbo.Set_Product_Promotion 1, 30.01', -1;
EXEC #Rc 'negative', N'dbo.Set_Product_Promotion 1, -1.00', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.f', 'Unit', 'BusinessSalesReport for Koshary El Tahrir in September';
EXEC #Cols 'columns', N'SELECT * FROM dbo.BusinessSalesReport(1, ''2026-09-01'', ''2026-09-30'')', 'product_id,product_name,units_sold,revenue_per_product';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (product_id INT, product_name VARCHAR(100), units_sold INT, revenue_per_product DECIMAL(10,2));
INSERT INTO #exp VALUES (1, 'Koshary Large', 2, 120.00), (2, 'Koshary Small', 3, 120.00), (3, 'Rice Pudding', 2, 40.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.BusinessSalesReport(1, ''2026-09-01'', ''2026-09-30'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.5.g', 'Unit', 'BusinessFeedbackOverview with star breakdown';
EXEC #Cols 'columns', N'SELECT * FROM dbo.BusinessFeedbackOverview(1)', 'avg_rating,number_of_feedbacks,five_star,four_star,three_star,two_star,one_star';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (avg_rating DECIMAL(10,2), number_of_feedbacks INT, five_star INT, four_star INT, three_star INT, two_star INT, one_star INT);
INSERT INTO #exp VALUES (3.50, 2, 1, 0, 0, 1, 0);
EXEC #Rows 'rows', N'SELECT * FROM dbo.BusinessFeedbackOverview(1)';
EXEC #End;
GO

/* ------------------------------------ 4.6 Customer ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.a-1', 'Unit', 'Add_Customer_Address adds an address that becomes the only active one';
EXEC #Rc 'add', N'dbo.Add_Customer_Address 17, ''New Street 5'', 1', 0;
EXEC #Eq 'active addresses', N'SELECT STRING_AGG(CAST(address_id AS VARCHAR(10)), '','') FROM dbo.Address WHERE customer_id = 17 AND is_active = 1', '13';
EXEC #Eq 'total addresses', N'SELECT COUNT(*) FROM dbo.Address WHERE customer_id = 17', '5', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.a-2', 'Unit', 'Add_Customer_Address returns -1 for an empty description';
EXEC #Rc 'empty description', N'dbo.Add_Customer_Address 17, '''', 1', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.b-1', 'Unit', 'Update_Delete_Customer_Address updates and deletes the customer''s own addresses';
EXEC #Rc 'update', N'dbo.Update_Delete_Customer_Address 17, 3, ''Dokki New Flat'', 1, ''Update''', 0;
EXEC #Eq 'updated', N'SELECT CONCAT(description, ''/'', zone_id) FROM dbo.Address WHERE address_id = 3', 'Dokki New Flat/1';
EXEC #Rc 'delete', N'dbo.Update_Delete_Customer_Address 17, 2, NULL, NULL, ''Delete''', 0;
EXEC #Eq 'deleted', N'SELECT COUNT(*) FROM dbo.Address WHERE address_id = 2', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.b-2', 'Unit', 'Update_Delete_Customer_Address returns -3 for another customer''s address and -4 for an address of a Placed/In Progress order or used by a cart';
EXEC #Rc 'not mine', N'dbo.Update_Delete_Customer_Address 17, 4, ''X'', 1, ''Update''', -3;
EXEC #Rc 'update address of an In Progress order', N'dbo.Update_Delete_Customer_Address 17, 1, ''X'', 1, ''Update''', -4;
EXEC #Rc 'delete address used by a cart', N'dbo.Update_Delete_Customer_Address 17, 3, NULL, NULL, ''Delete''', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.c-1', 'Unit', 'Change_Active_Address makes the selected address the only active one';
EXEC #Rc 'change', N'dbo.Change_Active_Address 17, 2', 0;
EXEC #Eq 'active addresses', N'SELECT STRING_AGG(CAST(address_id AS VARCHAR(10)), '','') FROM dbo.Address WHERE customer_id = 17 AND is_active = 1', '2';
EXEC #Eq 'carts untouched', N'SELECT COUNT(*) FROM dbo.Cart WHERE customer_id = 17 AND status = ''Active''', '2', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.c-2', 'Unit', 'Change_Active_Address returns -3 for an address that is not the customer''s';
EXEC #Rc 'not mine', N'dbo.Change_Active_Address 17, 4', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.d-1', 'Unit', 'Add_Card saves a card';
EXEC #Rc 'add', N'dbo.Add_Card 17, ''4999999999999999'', ''Ahmed Salem'', ''2031-01-31''', 0;
EXEC #Eq 'saved', N'SELECT COUNT(*) FROM dbo.Card WHERE customer_id = 17 AND card_no = ''4999999999999999''', '1', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.d-2', 'Unit', 'Add_Card returns -1 for an expired card or a bad number and -2 for a card already saved';
EXEC #Rc 'expired', N'dbo.Add_Card 17, ''4999999999999999'', ''Ahmed Salem'', ''2020-01-31''', -1;
EXEC #Rc 'short number', N'dbo.Add_Card 17, ''4999'', ''Ahmed Salem'', ''2031-01-31''', -1;
EXEC #Rc 'duplicate', N'dbo.Add_Card 17, ''4111111111111111'', ''Ahmed Salem'', ''2031-01-31''', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.e-1', 'Unit', 'Create_Cart creates an Active cart for the active address';
EXEC #Rc 'create', N'dbo.Create_Cart 23', 0;
EXEC #Eq 'cart', N'SELECT CONCAT(status, ''/'', address_id) FROM dbo.Cart WHERE customer_id = 23', 'Active/11';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.e-2', 'Unit', 'Create_Cart returns -2 when the active address already has an Active cart and -3 for a Blacklisted customer';
EXEC #Rc 'second active cart', N'dbo.Create_Cart 17', -2;
EXEC #Rc 'blacklisted', N'dbo.Create_Cart 21', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.f-1', 'Unit', 'Add_To_Cart adds a new line and increases an existing line, replacing the note';
EXEC #Rc 'new line', N'dbo.Add_To_Cart 9, 2, 2, NULL', 0;
EXEC #Eq 'new line', N'SELECT quantity FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 2', '2', 'INT';
EXEC #Rc 'existing line', N'dbo.Add_To_Cart 9, 1, 3, ''Spicy''', 0;
EXEC #Eq 'quantity and note', N'SELECT CONCAT(quantity, ''/'', notes) FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 1', '4/Spicy';
EXEC #Rc 'existing line, no new note', N'dbo.Add_To_Cart 9, 1, 1, NULL', 0;
EXEC #Eq 'note kept', N'SELECT CONCAT(quantity, ''/'', notes) FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 1', '5/Spicy';
EXEC #Eq 'unit price stays NULL', N'SELECT ISNULL(CAST(unit_price AS VARCHAR(20)), ''<null>'') FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 2', '<null>';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.f-2', 'Unit', 'Add_To_Cart returns -6 above 10, -5 outside the zone, -1 for quantity 0 and -4 for a cart that cannot be edited';
EXEC #Rc 'total above 10', N'dbo.Add_To_Cart 9, 1, 10, NULL', -6;
EXEC #Rc 'zone mismatch', N'dbo.Add_To_Cart 9, 11, 1, NULL', -5;
EXEC #Rc 'quantity 0', N'dbo.Add_To_Cart 9, 2, 0, NULL', -1;
EXEC #Rc 'checked out cart', N'dbo.Add_To_Cart 1, 2, 1, NULL', -4;
EXEC #Rc 'cart of an inactive address', N'dbo.Add_To_Cart 15, 11, 1, NULL', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.g', 'Unit', 'Remove_From_Cart removes a line; -4 for a Checked Out cart';
EXEC #Rc 'remove', N'dbo.Remove_From_Cart 9, 8', 0;
EXEC #Eq 'removed', N'SELECT COUNT(*) FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 8', '0', 'INT';
EXEC #Rc 'checked out cart', N'dbo.Remove_From_Cart 1, 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.h', 'Unit', 'Calculate_Voucher_Discount handles fixed, percentage, cap and invalid vouchers';
EXEC #Eq 'fixed', N'SELECT dbo.Calculate_Voucher_Discount(3, 200.00)', '50.00', 'DECIMAL(10,2)';
EXEC #Eq 'percentage', N'SELECT dbo.Calculate_Voucher_Discount(4, 200.00)', '20.00', 'DECIMAL(10,2)';
EXEC #Eq 'capped at the subtotal', N'SELECT dbo.Calculate_Voucher_Discount(3, 30.00)', '30.00', 'DECIMAL(10,2)';
EXEC #Eq 'used voucher', N'SELECT dbo.Calculate_Voucher_Discount(1, 100.00)', '0.00', 'DECIMAL(10,2)';
EXEC #Eq 'expired voucher', N'SELECT dbo.Calculate_Voucher_Discount(6, 100.00)', '0.00', 'DECIMAL(10,2)';
EXEC #Eq 'NULL voucher', N'SELECT dbo.Calculate_Voucher_Discount(NULL, 100.00)', '0.00', 'DECIMAL(10,2)';
EXEC #Eq 'missing voucher', N'SELECT dbo.Calculate_Voucher_Discount(999, 100.00)', '0.00', 'DECIMAL(10,2)';
EXEC #Eq 'negative subtotal is invalid', N'SELECT dbo.Calculate_Voucher_Discount(3, -5.00)', '-1.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.i-1', 'Unit', 'Checkout_Cart creates the order, SubOrders, Deliveries and Payment (voucher, wallet)';
EXEC #Rc 'checkout', N'dbo.Checkout_Cart 9, 3, ''Wallet'', NULL', 0;
EXEC #Eq 'order', N'SELECT CONCAT(status, ''/'', discount_amount, ''/'', total_amount, ''/'', zone_id, ''/'', voucher_id) FROM dbo.Orders WHERE cart_id = 9', 'Placed/50.00/140.00/1/3';
EXEC #Eq 'order date is now', N'SELECT CASE WHEN ABS(DATEDIFF(MINUTE, order_date, GETDATE())) <= 5 THEN 1 ELSE 0 END FROM dbo.Orders WHERE cart_id = 9', '1', 'INT';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, suborder_status VARCHAR(20), total_price DECIMAL(10,2), delivery_fee DECIMAL(10,2), rider_id INT);
INSERT INTO #exp VALUES (1, 'Assigned', 60.00, 20.00, 12), (3, 'Assigned', 90.00, 20.00, 13);
EXEC #Rows 'suborders and deliveries', N'SELECT s.business_id, s.status, s.total_price, s.delivery_fee, d.rider_id FROM dbo.SubOrder s JOIN dbo.Delivery d ON d.suborder_id = s.suborder_id WHERE s.order_id = (SELECT order_id FROM dbo.Orders WHERE cart_id = 9)';
GO
DROP TABLE IF EXISTS #exp;
GO
CREATE TABLE #exp (amount DECIMAL(10,2), currency VARCHAR(3), method VARCHAR(20), refunded_amount DECIMAL(10,2), card_id INT);
INSERT INTO #exp VALUES (140.00, 'EGP', 'Wallet', 0.00, NULL);
EXEC #Rows 'payment', N'SELECT amount, currency, method, refunded_amount, card_id FROM dbo.Payment WHERE order_id = (SELECT order_id FROM dbo.Orders WHERE cart_id = 9)';
EXEC #Eq 'wallet', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 17', '360.00', 'DECIMAL(10,2)';
EXEC #Eq 'voucher used', N'SELECT status FROM dbo.Voucher WHERE voucher_id = 3', 'Used';
EXEC #Eq 'cart status', N'SELECT status FROM dbo.Cart WHERE cart_id = 9', 'Checked Out';
EXEC #Eq 'frozen unit price', N'SELECT unit_price FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 8', '45.00', 'DECIMAL(10,2)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.i-2', 'Unit', 'Checkout_Cart returns -9 for an empty cart, -3 for a Blacklisted customer and -4 for a cart that cannot be checked out';
EXEC #Rc 'empty cart', N'dbo.Checkout_Cart 10, NULL, ''Cash'', NULL', -9;
EXEC #Rc 'blacklisted customer', N'dbo.Checkout_Cart 12, NULL, ''Cash'', NULL', -3;
EXEC #Rc 'cart of an inactive address', N'dbo.Checkout_Cart 15, NULL, ''Cash'', NULL', -4;
EXEC #Rc 'unavailable product', N'dbo.Checkout_Cart 14, NULL, ''Cash'', NULL', -4;
EXEC #Rc 'checked out cart', N'dbo.Checkout_Cart 1, NULL, ''Cash'', NULL', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.i-3', 'Unit', 'Checkout_Cart returns -7 when the payment cannot be made';
EXEC #Rc 'wallet too low', N'dbo.Checkout_Cart 11, NULL, ''Wallet'', NULL', -7;
EXEC #Rc 'card missing', N'dbo.Checkout_Cart 11, NULL, ''Card'', NULL', -7;
EXEC #Rc 'card of another customer', N'dbo.Checkout_Cart 11, NULL, ''Card'', 1', -7;
EXEC #Rc 'unknown method', N'dbo.Checkout_Cart 11, NULL, ''Cheque'', NULL', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.j-1', 'Unit', 'Cancel_Order cancels everything, refunds to the wallet and restores the voucher';
EXEC #Rc 'cancel', N'dbo.Cancel_Order 8', 0;
EXEC #Eq 'order', N'SELECT status FROM dbo.Orders WHERE order_id = 8', 'Cancelled';
EXEC #Eq 'suborder', N'SELECT status FROM dbo.SubOrder WHERE suborder_id = 12', 'Cancelled';
EXEC #Eq 'refund', N'SELECT refunded_amount FROM dbo.Payment WHERE order_id = 8', '155.00', 'DECIMAL(10,2)';
EXEC #Eq 'wallet', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 22', '180.00', 'DECIMAL(10,2)';
EXEC #Eq 'voucher', N'SELECT status FROM dbo.Voucher WHERE voucher_id = 5', 'Unused';
EXEC #Eq 'order unlinked from voucher', N'SELECT voucher_id FROM dbo.Orders WHERE order_id = 8', NULL, 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.j-2', 'Unit', 'Cancel_Order returns -4 when a SubOrder was picked up, the order is Cancelled or Delivered';
EXEC #Rc 'picked up', N'dbo.Cancel_Order 6', -4;
EXEC #Rc 'already cancelled', N'dbo.Cancel_Order 4', -4;
EXEC #Rc 'delivered', N'dbo.Cancel_Order 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.k-1', 'Unit', 'Reorder creates a new Active cart with the same items for the chosen address and makes it active';
EXEC #Rc 'reorder', N'dbo.Reorder 1, 10', 0;
EXEC #Eq 'new cart', N'SELECT CONCAT(status, ''/'', address_id, ''/'', customer_id) FROM dbo.Cart WHERE cart_id = (SELECT MAX(cart_id) FROM dbo.Cart)', 'Active/10/17';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (product_id INT, quantity INT, notes VARCHAR(255), unit_price DECIMAL(10,2));
INSERT INTO #exp VALUES (1, 2, 'Extra sauce', NULL), (5, 1, NULL, NULL);
EXEC #Rows 'items', N'SELECT product_id, quantity, notes, unit_price FROM dbo.CartItem WHERE cart_id = (SELECT MAX(cart_id) FROM dbo.Cart)';
EXEC #Eq 'address 10 is now the active one', N'SELECT STRING_AGG(CAST(address_id AS VARCHAR(10)), '','') FROM dbo.Address WHERE customer_id = 17 AND is_active = 1', '10';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.k-2', 'Unit', 'Reorder returns -3 (Blacklisted or not my address), -5 (zone differs) and -2 (address already has an Active cart)';
EXEC #Rc 'blacklisted customer', N'dbo.Reorder 4, 7', -3;
EXEC #Rc 'not my address', N'dbo.Reorder 1, 4', -3;
EXEC #Rc 'other zone', N'dbo.Reorder 1, 2', -5;
EXEC #Rc 'address with an Active cart', N'dbo.Reorder 1, 1', -2;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.l-1', 'Unit', 'Submit_Feedback stores feedback for a Delivered SubOrder';
EXEC #Rc 'feedback', N'dbo.Submit_Feedback 2, ''Nice pizza'', ''Arrived hot'', 4', 0;
EXEC #Eq 'stored', N'SELECT CONCAT(headline, ''/'', rating) FROM dbo.Feedback WHERE suborder_id = 2', 'Nice pizza/4';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.l-2', 'Unit', 'Submit_Feedback returns -2 for a second feedback, -4 for a SubOrder not delivered and -1 for a rating of 6';
EXEC #Rc 'second feedback', N'dbo.Submit_Feedback 1, ''Again'', NULL, 5', -2;
EXEC #Rc 'not delivered', N'dbo.Submit_Feedback 9, ''Early'', NULL, 5', -4;
EXEC #Rc 'rating 6', N'dbo.Submit_Feedback 2, ''Wow'', NULL, 6', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.m-1', 'Unit', 'Rate_Rider stores the rider rating';
EXEC #Rc 'rate', N'dbo.Rate_Rider 4, 5', 0;
EXEC #Eq 'stored', N'SELECT rider_rating FROM dbo.Delivery WHERE suborder_id = 4', '5', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.m-2', 'Unit', 'Rate_Rider returns -2 for a second rating, -4 for a SubOrder not delivered and -1 for a rating of 0';
EXEC #Rc 'second rating', N'dbo.Rate_Rider 1, 3', -2;
EXEC #Rc 'not delivered', N'dbo.Rate_Rider 9, 3', -4;
EXEC #Rc 'rating 0', N'dbo.Rate_Rider 4, 0', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.n', 'Unit', 'My_Order_History lists all orders of the customer';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Order_History(17)', 'order_id,order_date,zone_name,status,number_of_suborders,discount_amount,total_amount,payment_method,refunded_amount';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (order_id INT, order_date DATETIME, zone_name VARCHAR(50), status VARCHAR(20), number_of_suborders INT, discount_amount DECIMAL(10,2), total_amount DECIMAL(10,2), payment_method VARCHAR(20), refunded_amount DECIMAL(10,2));
INSERT INTO #exp VALUES (1, '2026-09-01 12:00', 'Maadi', 'Delivered', 2, 0.00, 260.00, 'Card', 0.00), (6, '2026-09-20 18:00', 'Maadi', 'In Progress', 2, 0.00, 190.00, 'Card', 0.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.My_Order_History(17)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.o-1', 'Unit', 'Toggle_Favorite adds and then removes a product favorite';
EXEC #Rc 'add', N'dbo.Toggle_Favorite 17, 2, ''Product''', 0;
EXEC #Eq 'added', N'SELECT COUNT(*) FROM dbo.Favorite_Product WHERE customer_id = 17 AND product_id = 2', '1', 'INT';
EXEC #Rc 'remove', N'dbo.Toggle_Favorite 17, 2, ''Product''', 0;
EXEC #Eq 'removed', N'SELECT COUNT(*) FROM dbo.Favorite_Product WHERE customer_id = 17 AND product_id = 2', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.o-2', 'Unit', 'Toggle_Favorite removes an existing business favorite and returns -1 for an unknown item type';
EXEC #Rc 'remove business', N'dbo.Toggle_Favorite 17, 1, ''Business''', 0;
EXEC #Eq 'removed', N'SELECT COUNT(*) FROM dbo.Favorite_Business WHERE customer_id = 17', '0', 'INT';
EXEC #Rc 'unknown type', N'dbo.Toggle_Favorite 17, 1, ''Order''', -1;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.p', 'Unit', 'My_Favorites lists favorite products only, with is_orderable';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Favorites(17)', 'product_id,product_name,business_name,is_orderable';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (product_id INT, product_name VARCHAR(100), business_name VARCHAR(100), is_orderable BIT);
INSERT INTO #exp VALUES (5, 'Margherita Pizza', 'Pizza Roma', 1);
EXEC #Rows 'customer 17', N'SELECT * FROM dbo.My_Favorites(17)';
DELETE FROM #exp;
INSERT INTO #exp VALUES (15, 'Basbousa', 'Sweet Corner', 0);
EXEC #Rows 'customer 19 (suspended business)', N'SELECT * FROM dbo.My_Favorites(19)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.6.q', 'Unit', 'Recommended_Products: unseen products of ordered categories in the active address zone, most ordered category first';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Recommended_Products(17)', 'product_id,product_name,business_name,category,final_price';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (product_id INT, product_name VARCHAR(100), business_name VARCHAR(100), category VARCHAR(50), final_price DECIMAL(10,2));
INSERT INTO #exp VALUES (18, 'Hawawshi', 'Koshary El Tahrir', 'Main Dishes', 50.00), (6, 'Pepperoni Pizza', 'Pizza Roma', 'Pizza', 150.00), (19, 'Face Mask', 'Seif Pharmacy', 'Hygiene', 15.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.Recommended_Products(17)';
EXEC #End;
GO

/* ------------------------------------ 4.7 Rider ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.a', 'Unit', 'Set_Rider_Availability makes a rider available; -3 for a user who is not a rider';
EXEC #Rc 'set', N'dbo.Set_Rider_Availability 14, 1', 0;
EXEC #Eq 'flag', N'SELECT is_available FROM dbo.Rider WHERE rider_id = 14', '1', 'BIT';
EXEC #Rc 'not a rider', N'dbo.Set_Rider_Availability 17, 1', -3;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.b', 'Unit', 'My_Active_Deliveries lists Assigned and Picked Up deliveries';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Active_Deliveries(12)', 'delivery_id,order_id,suborder_id,business_name,customer_name,address_description,zone_name,status,assigned_at';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (delivery_id INT, order_id INT, suborder_id INT, business_name VARCHAR(100), customer_name VARCHAR(101), address_description VARCHAR(150), zone_name VARCHAR(50), status VARCHAR(20), assigned_at DATETIME);
INSERT INTO #exp VALUES
    (9, 6, 9, 'Koshary El Tahrir', 'Ahmed Salem', 'Street 9 Building 12', 'Maadi', 'Picked Up', '2026-09-20 18:00'),
    (11, 7, 11, 'Seif Pharmacy', 'Sara Mostafa', 'Road 233 Villa 7', 'Maadi', 'Assigned', '2026-09-21 10:00');
EXEC #Rows 'rows', N'SELECT * FROM dbo.My_Active_Deliveries(12)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.c-1', 'Unit', 'Mark_Picked_Up updates the delivery, the SubOrder and the order';
EXEC #Rc 'pick up', N'dbo.Mark_Picked_Up 11', 0;
EXEC #Eq 'suborder', N'SELECT status FROM dbo.SubOrder WHERE suborder_id = 11', 'Picked Up';
EXEC #Eq 'picked_up_at stamped', N'SELECT CASE WHEN ABS(DATEDIFF(MINUTE, picked_up_at, GETDATE())) <= 5 THEN 1 ELSE 0 END FROM dbo.Delivery WHERE delivery_id = 11', '1', 'INT';
EXEC #Eq 'order', N'SELECT status FROM dbo.Orders WHERE order_id = 7', 'In Progress';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.c-2', 'Unit', 'Mark_Picked_Up returns -4 for Delivered, Cancelled and already Picked Up deliveries';
EXEC #Rc 'delivered', N'dbo.Mark_Picked_Up 1', -4;
EXEC #Rc 'cancelled', N'dbo.Mark_Picked_Up 6', -4;
EXEC #Rc 'already picked up', N'dbo.Mark_Picked_Up 9', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.d-1', 'Unit', 'Mark_Delivered stamps delivered_at, computes tracking_time and recomputes the order';
EXEC #Rc 'deliver', N'dbo.Mark_Delivered 9', 0;
EXEC #Eq 'suborder', N'SELECT status FROM dbo.SubOrder WHERE suborder_id = 9', 'Delivered';
EXEC #Eq 'delivered_at stamped', N'SELECT CASE WHEN ABS(DATEDIFF(MINUTE, delivered_at, GETDATE())) <= 5 THEN 1 ELSE 0 END FROM dbo.Delivery WHERE delivery_id = 9', '1', 'INT';
EXEC #Eq 'tracking_time in minutes since pickup', N'SELECT CASE WHEN tracking_time = DATEDIFF(MINUTE, picked_up_at, delivered_at) THEN 1 ELSE 0 END FROM dbo.Delivery WHERE delivery_id = 9', '1', 'INT';
EXEC #Eq 'order still In Progress (SubOrder 10 not delivered)', N'SELECT status FROM dbo.Orders WHERE order_id = 6', 'In Progress';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.d-2', 'Unit', 'Mark_Delivered returns -4 for a delivery that was not picked up';
EXEC #Rc 'assigned only', N'dbo.Mark_Delivered 11', -4;
EXEC #Rc 'already delivered', N'dbo.Mark_Delivered 1', -4;
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.e', 'Unit', 'My_Earnings for September (80% of the fees of delivered deliveries)';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Earnings(12, ''2026-09-01'', ''2026-09-30'')', 'completed_deliveries,total_delivery_fees,total_earnings';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (completed_deliveries INT, total_delivery_fees DECIMAL(10,2), total_earnings DECIMAL(10,2));
INSERT INTO #exp VALUES (2, 40.00, 32.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.My_Earnings(12, ''2026-09-01'', ''2026-09-30'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.f', 'Unit', 'My_Rating_Summary with star breakdown';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Rating_Summary(12)', 'avg_rating,ratings_count,five_star,four_star,three_star,two_star,one_star';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (avg_rating DECIMAL(10,2), ratings_count INT, five_star INT, four_star INT, three_star INT, two_star INT, one_star INT);
INSERT INTO #exp VALUES (4.50, 2, 1, 1, 0, 0, 0);
EXEC #Rows 'rows', N'SELECT * FROM dbo.My_Rating_Summary(12)';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.7.g', 'Unit', 'My_Delivery_History lists Delivered and Cancelled deliveries assigned in the range';
EXEC #Cols 'columns', N'SELECT * FROM dbo.My_Delivery_History(12, ''2026-09-01'', ''2026-09-30'')', 'delivery_id,order_id,business_name,status,assigned_at,picked_up_at,delivered_at,tracking_time';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (delivery_id INT, order_id INT, business_name VARCHAR(100), status VARCHAR(20), assigned_at DATETIME, picked_up_at DATETIME, delivered_at DATETIME, tracking_time INT);
INSERT INTO #exp VALUES
    (1, 1, 'Koshary El Tahrir', 'Delivered', '2026-09-01 12:00', '2026-09-01 12:10', '2026-09-01 12:40', 30),
    (3, 2, 'Seif Pharmacy', 'Delivered', '2026-09-02 19:00', '2026-09-02 19:05', '2026-09-02 19:30', 25),
    (6, 4, 'Pizza Roma', 'Cancelled', '2026-09-10 20:00', NULL, NULL, NULL);
EXEC #Rows 'rows', N'SELECT * FROM dbo.My_Delivery_History(12, ''2026-09-01'', ''2026-09-30'')';
EXEC #End;
GO

/* ------------------------------------ 4.8 System ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.8.a', 'Unit', 'Search_Platform ranks Active businesses of the customer''s active address zone by match type';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Search_Platform(17, ''Pizza'')', 'business_id,business_name,priority';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, business_name VARCHAR(100), priority INT);
INSERT INTO #exp VALUES (2, 'Pizza Roma', 2);
EXEC #Rows 'starts with', N'SELECT * FROM dbo.Search_Platform(17, ''Pizza'')';
DELETE FROM #exp;
INSERT INTO #exp VALUES (3, 'Seif Pharmacy', 1);
EXEC #Rows 'exact', N'SELECT * FROM dbo.Search_Platform(17, ''Seif Pharmacy'')';
DELETE FROM #exp;
INSERT INTO #exp VALUES (3, 'Seif Pharmacy', 3);
EXEC #Rows 'contains', N'SELECT * FROM dbo.Search_Platform(17, ''Pharm'')';
DELETE FROM #exp;
EXEC #Rows 'other zone is hidden', N'SELECT * FROM dbo.Search_Platform(17, ''Sushi'')';
DELETE FROM #exp;
EXEC #Rows 'pending business is hidden', N'SELECT * FROM dbo.Search_Platform(19, ''Pharmacy'')';
DELETE FROM #exp;
INSERT INTO #exp VALUES (1, 'Koshary El Tahrir', 3), (2, 'Pizza Roma', 3), (3, 'Seif Pharmacy', 3);
EXEC #Rows 'contains in several', N'SELECT * FROM dbo.Search_Platform(17, ''a'')';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.8.b', 'Unit', 'Reconcile_Order_Totals is empty on consistent data and reports tampered orders';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Reconcile_Order_Totals()', 'order_id,expected_total,order_total,payment_amount';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (order_id INT, expected_total DECIMAL(10,2), order_total DECIMAL(10,2), payment_amount DECIMAL(10,2));
EXEC #Rows 'consistent seed', N'SELECT * FROM dbo.Reconcile_Order_Totals()';
EXEC #Exec N'UPDATE dbo.Payment SET amount = 250.00 WHERE order_id = 1; DELETE FROM dbo.Payment WHERE order_id = 7; UPDATE dbo.Orders SET total_amount = 150.00 WHERE order_id = 2;';
INSERT INTO #exp VALUES (1, 260.00, 260.00, 250.00), (7, 100.00, 100.00, NULL), (2, 140.00, 150.00, 140.00);
EXEC #Rows 'tampered', N'SELECT * FROM dbo.Reconcile_Order_Totals()';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.8.c', 'Unit', 'Nearby_Businesses_By_Category for Desserts near a Maadi address';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Nearby_Businesses_By_Category(1, ''Desserts'')', 'business_id,business_name,zone_name,same_zone,zone_avg_delivery_time';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (business_id INT, business_name VARCHAR(100), zone_name VARCHAR(50), same_zone BIT, zone_avg_delivery_time DECIMAL(10,2));
INSERT INTO #exp VALUES (1, 'Koshary El Tahrir', 'Maadi', 1, 22.50), (2, 'Pizza Roma', 'Maadi', 1, 22.50), (4, 'Sushi Zen', 'Zamalek', 0, 35.00);
EXEC #Rows 'rows', N'SELECT * FROM dbo.Nearby_Businesses_By_Category(1, ''Desserts'')';
EXEC #Eq 'same zone first', N'SELECT TOP 1 business_id FROM dbo.Nearby_Businesses_By_Category(1, ''Desserts'') ORDER BY same_zone DESC, zone_avg_delivery_time, business_id', '1';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PU-4.8.d', 'Unit', 'Platform_Health_Snapshot on the seed data';
EXEC #Cols 'columns', N'SELECT * FROM dbo.Platform_Health_Snapshot()', 'active_businesses,available_riders,orders_today,avg_delivery_time_today,low_ratings_today';
DROP TABLE IF EXISTS #exp;
CREATE TABLE #exp (active_businesses INT, available_riders INT, orders_today INT, avg_delivery_time_today DECIMAL(10,2), low_ratings_today INT);
INSERT INTO #exp VALUES (5, 4, 0, NULL, 0);
EXEC #Rows 'rows', N'SELECT * FROM dbo.Platform_Health_Snapshot()';
EXEC #End;
GO

/* ------------------------------------ Path tests ------------------------------------ */
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PP-1', 'Path', 'New customer: register, address, card, voucher, cart, checkout, delivery, feedback, rating';
EXEC #Rc 'register', N'dbo.Customer_Register ''Mariam'', NULL, ''Wael'', ''mariam.wael'', ''Pass@025'', ''mariam.wael@mail.com'', ''01000000025'', ''2001-05-05''', 0;
EXEC #Eq 'login works', N'SELECT dbo.CustomerLoginValidation(''mariam.wael'', ''Pass@025'')', '1', 'BIT';
EXEC #Rc 'address', N'dbo.Add_Customer_Address 25, ''Corniche Tower 2'', 1', 0;
EXEC #Rc 'card', N'dbo.Add_Card 25, ''4555555555555555'', ''Mariam Wael'', ''2031-12-31''', 0;
EXEC #Rc 'voucher', N'dbo.Issue_Voucher 25, ''MARIAM10'', 1, 10.00, ''2030-12-31'', 1', 0;
EXEC #Rc 'cart', N'dbo.Create_Cart 25', 0;
EXEC #Rc 'add 1', N'dbo.Add_To_Cart 16, 2, 2, NULL', 0;
EXEC #Rc 'add 2', N'dbo.Add_To_Cart 16, 9, 1, ''Sealed box''', 0;
EXEC #Rc 'checkout', N'dbo.Checkout_Cart 16, 8, ''Card'', 6', 0;
EXEC #Eq 'order (80 + 80 = 160, 10% = 16, + 2 x 20)', N'SELECT CONCAT(discount_amount, ''/'', total_amount, ''/'', status) FROM dbo.Orders WHERE cart_id = 16', '16.00/184.00/Placed';
EXEC #Eq 'card charged', N'SELECT CONCAT(p.method, ''/'', p.amount, ''/'', p.card_id) FROM dbo.Payment p JOIN dbo.Orders o ON o.order_id = p.order_id WHERE o.cart_id = 16', 'Card/184.00/6';
EXEC #Exec N'DECLARE @d1 INT = (SELECT d.delivery_id FROM dbo.Delivery d JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.cart_id = 16 AND s.business_id = 1);
             DECLARE @d3 INT = (SELECT d.delivery_id FROM dbo.Delivery d JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.cart_id = 16 AND s.business_id = 3);
             EXEC dbo.Mark_Picked_Up @d1; EXEC dbo.Mark_Picked_Up @d3; EXEC dbo.Mark_Delivered @d1;';
EXEC #Eq 'order in progress after one delivery', N'SELECT status FROM dbo.Orders WHERE cart_id = 16', 'In Progress';
EXEC #Exec N'DECLARE @d3 INT = (SELECT d.delivery_id FROM dbo.Delivery d JOIN dbo.SubOrder s ON s.suborder_id = d.suborder_id JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.cart_id = 16 AND s.business_id = 3);
             EXEC dbo.Mark_Delivered @d3;';
EXEC #Eq 'order delivered', N'SELECT status FROM dbo.Orders WHERE cart_id = 16', 'Delivered';
EXEC #Exec N'DECLARE @s1 INT = (SELECT s.suborder_id FROM dbo.SubOrder s JOIN dbo.Orders o ON o.order_id = s.order_id WHERE o.cart_id = 16 AND s.business_id = 1);
             EXEC dbo.Submit_Feedback @s1, ''Lovely'', ''Hot food'', 5; EXEC dbo.Rate_Rider @s1, 4;';
EXEC #Eq 'voucher used', N'SELECT status FROM dbo.Voucher WHERE promo_code = ''MARIAM10''', 'Used';
EXEC #Eq 'business rating updated', N'SELECT avg_rating FROM dbo.BusinessRatingsSummary WHERE business_id = 1', '4.00', 'DECIMAL(10,2)';
EXEC #Eq 'rider rating updated', N'SELECT avg_rating FROM dbo.RiderPerformanceSummary WHERE rider_id = 12', '4.33', 'DECIMAL(10,2)';
EXEC #Eq 'totals reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PP-2', 'Path', 'New partner: register, business, product, approval, search and add to cart';
EXEC #Rc 'partner', N'dbo.Partner_Register ''Omar'', NULL, ''Fawzy'', ''omar.fawzy'', ''Pass@025'', ''omar.fawzy@mail.com'', ''01000000025'', ''1988-08-08''', 0;
EXEC #Rc 'business', N'dbo.Register_Business 25, ''Fawzy Bakery'', ''Fresh bread'', NULL, 1, ''00:00'', ''00:00'', 20, ''02200000025'', ''Restaurant'', ''Egyptian'', ''Bakery'', NULL', 0;
EXEC #Rc 'product', N'dbo.Upsert_Product 9, NULL, ''Baladi Bread'', ''5 loaves'', ''Bakery'', 10.00, 1', 0;
EXEC #Eq 'listed as pending', N'SELECT COUNT(*) FROM dbo.PendingBusinessApprovals WHERE business_name = ''Fawzy Bakery''', '1', 'INT';
EXEC #Eq 'invisible while pending', N'SELECT COUNT(*) FROM dbo.Search_Platform(17, ''Fawzy'')', '0', 'INT';
EXEC #Rc 'product cannot be carted while pending', N'dbo.Add_To_Cart 9, 21, 4, NULL', -4;
EXEC #Rc 'approve', N'dbo.Approve_Business 9, 2', 0;
EXEC #Eq 'no longer pending', N'SELECT COUNT(*) FROM dbo.PendingBusinessApprovals WHERE business_name = ''Fawzy Bakery''', '0', 'INT';
EXEC #Eq 'visible after approval', N'SELECT business_name FROM dbo.Search_Platform(17, ''Fawzy'')', 'Fawzy Bakery';
EXEC #Rc 'add to cart', N'dbo.Add_To_Cart 9, 21, 4, NULL', 0;
EXEC #Eq 'in the cart', N'SELECT quantity FROM dbo.CartItem WHERE cart_id = 9 AND product_id = 21', '4', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PP-3', 'Path', 'Cancel an order, get the voucher back and use it on a new order';
EXEC #Rc 'cancel', N'dbo.Cancel_Order 8', 0;
EXEC #Eq 'voucher visible again', N'SELECT COUNT(*) FROM dbo.ActiveVouchers WHERE voucher_id = 5', '1', 'INT';
EXEC #Rc 'remove the unavailable product', N'dbo.Remove_From_Cart 14, 4', 0;
EXEC #Rc 'add', N'dbo.Add_To_Cart 14, 7, 1, NULL', 0;
EXEC #Rc 'checkout', N'dbo.Checkout_Cart 14, 5, ''Wallet'', NULL', 0;
EXEC #Eq 'new total (70 - 15 + 20)', N'SELECT total_amount FROM dbo.Orders WHERE cart_id = 14', '75.00', 'DECIMAL(10,2)';
EXEC #Eq 'voucher linked and used', N'SELECT CONCAT(o.voucher_id, ''/'', v.status) FROM dbo.Orders o JOIN dbo.Voucher v ON v.voucher_id = o.voucher_id WHERE o.cart_id = 14', '5/Used';
EXEC #Eq 'wallet (25 + 155 refund - 75)', N'SELECT wallet_balance FROM dbo.Customer WHERE customer_id = 22', '105.00', 'DECIMAL(10,2)';
EXEC #Eq 'totals reconcile', N'SELECT COUNT(*) FROM dbo.Reconcile_Order_Totals()', '0', 'INT';
EXEC #End;
GO
DROP TABLE IF EXISTS #exp;
GO
EXEC #Begin 'PP-4', 'Path', 'Blacklist a customer, see the effects on login and carts, and lift the blacklist';
EXEC #Rc 'blacklist customer 17', N'dbo.Blacklist_Customer 17, 1, ''Fraud ring''', 0;
EXEC #Eq 'cannot log in', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017'')', '0', 'BIT';
EXEC #Eq 'delivered and picked up orders are kept', N'SELECT STRING_AGG(CONCAT(order_id, '':'', status), '','') WITHIN GROUP (ORDER BY order_id) FROM dbo.My_Order_History(17)', '1:Delivered,6:In Progress';
EXEC #Eq 'unused vouchers deleted', N'SELECT COUNT(*) FROM dbo.Voucher WHERE customer_id = 17', '0', 'INT';
EXEC #Rc 'checkout blocked', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', -3;
EXEC #Rc 'other admin cannot lift', N'dbo.Lift_Customer_Blacklist 17, 2', -3;
EXEC #Rc 'blacklisting admin lifts', N'dbo.Lift_Customer_Blacklist 17, 1', 0;
EXEC #Eq 'can log in again', N'SELECT dbo.CustomerLoginValidation(''ahmed.salem'', ''Pass@017'')', '1', 'BIT';
EXEC #Rc 'checkout works again', N'dbo.Checkout_Cart 9, NULL, ''Cash'', NULL', 0;
EXEC #End;
GO

/* ------------------------------------ Report ------------------------------------ */
EXEC #ResetData;   -- leave the database with the original seed data
GO
SELECT test_id,
       kind,
       description,
       CASE WHEN finished = 1 AND fail_count = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
       CASE WHEN finished = 0 THEN N'Test stopped early. ' + details ELSE details END AS details
FROM #TestResults
ORDER BY seq;

SELECT COUNT(*) AS total_tests,
       SUM(CASE WHEN finished = 1 AND fail_count = 0 THEN 1 ELSE 0 END) AS passed,
       SUM(CASE WHEN finished = 1 AND fail_count = 0 THEN 0 ELSE 1 END) AS failed
FROM #TestResults;

DECLARE @passed INT = (SELECT COUNT(*) FROM #TestResults WHERE finished = 1 AND fail_count = 0);
DECLARE @total INT = (SELECT COUNT(*) FROM #TestResults);
PRINT CONCAT('Passed ', @passed, ' of ', @total, ' tests.');
GO
SET NOEXEC OFF;
GO
