# Milestone 2 — Local Business Delivery and Fulfillment Management System

Media Engineering and Technology · Databases I · Winter 2026
**Submission deadline: 19/11/2026, 11:59 PM.** Team 28 → file `Team_28.sql`, database `LocalDeliveryMarketplace_Team_28`.

Source: `docs/Milestone 2, Project Description.pdf`, the original assignment PDF, transcribed in full. Read the PDF only if something here is vague or looks wrong. The PDF's printed page N is PDF page N+1. Its text layer scrambles the Appendix A tables under `pdftotext -layout`; use `pdftotext -table` instead. Section 6 (public tests) comes from `tests/Milestone 2, Public Tests Guide.pdf`.

Revision history:
- 2026-11-14: first transcription.
- 2026-11-14: updated to the revised project description. Added the authorization rule (Section 1, Implementation rules) and Recommended_Products in Student 5's Hard column (Section 5). Nothing else changed, including the schema. Added Section 6 from the public tests guide.

Transcription notes (inconsistencies found in the PDF itself; see `AGENTS.md` for the AI clause):
- Section 5 assigns **Detect_Voucher_Abuse** to Student 1, but Section 4 never specifies it.
- **Recommended_Products** (4.6.q) is tagged [Hard], and the revised Section 5 lists it as a Hard item for Student 5. But it is still missing from Section 1's list of 8 hard requirements, it is still in Student 2's "Other" list, and the Section 5 intro still says Student 5 gets one hard requirement.
- Appendix A gives no CHECK constraints for status/type columns, though Section 1 says they must store exactly the Section 2.3 values.

---

## 1. Important Guidelines

The description is subject to minor changes announced on CMS.

### Submission
- Submit one SQL file named after the team number (e.g. `Team_10.sql`) via CMS. It contains the database creation statement followed by every required table, procedure, function and view, **in the order of Section 4**.
- The file must run top to bottom on a fresh SQL Server instance without errors. Code that does not compile is not graded.
- One submission per team. Hard deadline, no extensions, no email submissions. Cheating cases are graded zero for the whole milestone. *(PDF also says: "AI tool use is prohibited and is treated as cheating." — superseded for this team, see `AGENTS.md`.)*

### Team work and hard requirements
- Exactly 5 students per team. The 8 hard requirements (marked [Hard]/[Hardest]): **TopSellingProducts, Suspend_Business, Reinstate_Business, Blacklist_Customer, Checkout_Cart, Cancel_Order, Search_Platform, Reconcile_Order_Totals**. Every student implements at least 1, following the Section 5 work split.
- Put the **name and ID of the implementing student in a comment directly above every procedure, function and view**. Unnamed items are credited to no one.
- The Section 5 split must be used to avoid a penalty.

### Data types and naming
- Alphanumeric attributes use the varchar sizes of Appendix A; procedure/function parameters use the size of the attribute they're stored in. Every surrogate ID is `int identity(1,1)`.
- Subclass tables (Admin, Partner, Rider, Customer, Restaurant, Pharmacy) use the superclass key as PK and have no identity column.
- Money `decimal(10,2)`. Quantities, ratings, minutes `int`. Flags `bit`. Dates `date`, points in time `datetime`, opening/closing hours `time`. Phone numbers `char(11)`, card numbers `char(16)`.
- Follow exactly: table names, column names, column order, data types and constraints (Section 3 + Appendix A); names of all procedures/functions/views; order and types of their parameters; order of returned columns. Any mismatch loses marks. No extra tables or columns.
- Status and type columns store exactly the values of Section 2.3.

### Input validation
Requirements describe only business logic. Work out from the schema, Appendix A and the business rules which inputs are invalid, and handle them.

### Error codes
Every stored procedure returns 0 on success and a Section 2.4 code on any error. Every function returns a Section 2.4 code on error as explained there.

### Implementation rules
- When a requirement says reject, or input is invalid, leave the database unchanged and return the matching error code.
- Procedures changing more than one row or table run inside a transaction (all or nothing).
- Functions can't modify data, so every data-changing requirement is a stored procedure.
- Unless stated otherwise, input IDs can be assumed to exist. Helper functions/procedures are allowed; `dropAllProceduresFunctionsViews` must drop them too.
- Authorization is not universally required in this milestone. If an SP/function/view needs authorization but no ID is passed as input for it, assume the authorization step is delayed to MS3 (i.e. skip it).

---

## 2. Background and Business Rules

### 2.1 Background
A local delivery marketplace (like food/pharmacy delivery apps). Partners own businesses (restaurants and pharmacies), customers order from them, riders deliver, admins run the platform. The platform works in zones (e.g. Maadi, Zamalek). Every business, customer address and rider belongs to one zone; every zone has a fixed delivery fee. A customer can only order from businesses in the zone of the delivery address.

- **Onboarding.** A partner registers a business, which stays Pending (invisible) until an admin approves it (Active) or rejects it (Rejected). A partner whose business was rejected can register it again. The partner manages the catalog, prices and discounts.
- **Shopping.** A customer saves addresses and cards, selects exactly one address as active, creates a cart linked automatically to the active address, and adds products, possibly from several businesses of the same zone.
- **Checkout.** The cart becomes an order split into one suborder per business. Each suborder gets a delivery auto-assigned to a rider of the zone. The customer pays once for the whole order with exactly one payment method and may use one voucher.
- **Delivery and after.** Riders mark deliveries picked up and delivered. The customer can then rate the business (feedback) and the rider.
- **Exceptions.** A customer can cancel an order until something is picked up. An admin can suspend a business (cancelling its suborders not yet picked up) and blacklist a fraudulent customer. Every cancellation produces a refund recorded on the payment.

### 2.2 Business Rules

- **BR-1.** `Users.account_status` is Active or Blacklisted. Only customers are blacklisted, by an admin. A Blacklisted customer cannot log in, create carts, check out, reorder or receive vouchers.
- **BR-2.** An admin is a Super Admin (default, `Admin.zone_id` NULL) or a Zone Admin (exactly one zone; a zone may have several Zone Admins). Only a Super Admin creates admins and zones, changes zone fees, assigns Zone Admins and reinstates businesses.
- **BR-3.** A Zone Admin may only approve, reject or suspend businesses of their zone, and only blacklist customers with at least one address (active or not) in their zone. A Super Admin may act on any business or customer. A blacklist is lifted only by the admin who set it (BR-4).
- **BR-4. Blacklist.** Reason and admin of a blacklisted customer are stored in Blacklist (3.14). One admin can blacklist many customers; a customer has exactly one blacklisting admin, who is the only one who can lift it (not even a Super Admin otherwise).
- **BR-5.** Customers only see Active businesses, and only products with `is_available = 1` of Active businesses. Products are never deleted once ordered; they're deactivated instead.
- **BR-6.** A business is open when the current time is in `[opening_hour, closing_hour)`. If `opening_hour > closing_hour` it works past midnight (open when now ≥ opening_hour or now < closing_hour). If equal, open 24 hours.
- **BR-7.** `Product.discount_amount` is a fixed amount between 0 and 50% of price (default 0). Effective unit price = price − discount_amount.
- **BR-8.** A customer has exactly one active address at a time (`Address.is_active = 1`), chosen by the customer and changeable. A cart belongs to one customer and one of their addresses; new carts and orders always use the active address automatically (customer isn't asked). At most one Active cart per address, so only one Active cart for the active address, and only that cart can be edited or checked out. All its products must come from businesses in the zone of that address; if the active address isn't in a business's zone, reject with the zone-mismatch code. An Active cart can be edited; a Checked Out cart is frozen and is the item list of its order. `CartItem.unit_price` is NULL until checkout. `CartItem.quantity` is 1–10.
- **BR-9. Pricing at checkout:** `SubOrder.total_price` = Σ quantity × unit_price of its items. `SubOrder.delivery_fee` = current zone fee. Subtotal = Σ total_price. `Orders.discount_amount` = voucher discount on the subtotal. `Orders.total_amount` = subtotal + Σ delivery_fee − discount_amount. `Payment.amount` = `Orders.total_amount`. These never change afterwards; cancellations are recorded as refunds.
- **BR-10. Payment methods:** Cash (paid to rider), Card (whole amount on one card), Wallet (whole amount from wallet). Exactly one method per order; no split payment. `Payment.card_id` is the charged card (NULL if none). Currency EGP.
- **BR-11.** `Orders.status` is recomputed whenever a SubOrder status changes: **Cancelled** if all SubOrders Cancelled; else **Delivered** if all non-cancelled SubOrders Delivered; else **In Progress** if any SubOrder Picked Up or Delivered; else **Placed**. A customer may place several orders without waiting; each checkout creates a new order starting as Placed.
- **BR-12.** `SubOrder.status` goes Placed → Assigned → Picked Up → Delivered, or Placed/Assigned → Cancelled. Placed when created, Assigned when its Delivery is assigned to a rider. Delivery has no status: it is Assigned/Picked Up/Delivered/Cancelled as its SubOrder is. An *active delivery* is one whose SubOrder is Assigned or Picked Up. The *least-busy available rider* of a zone is the rider of that zone with `is_available = 1` and an Active account having the fewest active deliveries (ties: smallest rider_id).
- **BR-13.** A voucher is valid for a checkout if it belongs to the customer, is Unused and `expiry_date` ≥ today. At most one voucher per order. Discount: if `is_percentage = 1`, subtotal × amount / 100 (amount 1–100); otherwise the fixed amount. Applies to the subtotal only and never exceeds it. Used vouchers are never deleted. A customer's Unused vouchers are deleted when they're blacklisted (no Revoked status).
- **BR-14.** Only a Placed or Assigned SubOrder can be cancelled. Refund of one SubOrder = total_price + delivery_fee, capped so `Payment.refunded_amount` never exceeds `Payment.amount`; cancelling a whole order refunds the remaining amount. Refunds are added to `Payment.refunded_amount` and, except for Cash, credited to the customer's `wallet_balance`. The wallet is filled only by refunds.

### 2.3 Allowed Values and Constants

| Column or constant | Allowed values or value | Default |
|---|---|---|
| Users.account_status | Active, Blacklisted | Active |
| Admin.role | Super Admin, Zone Admin | Super Admin |
| Business.status | Pending, Active, Suspended, Rejected | Pending |
| Cart.status | Active, Checked Out | Active |
| Orders.status | Placed, In Progress, Delivered, Cancelled | Placed |
| SubOrder.status | Placed, Assigned, Picked Up, Delivered, Cancelled | Placed |
| Voucher.status | Unused, Used | Unused |
| Payment.method | Cash, Card, Wallet | none |
| business_type | Restaurant, Pharmacy | none |
| item_type / action | Business, Product / Add, Update, Remove | none |
| Platform commission | 10% of total_price of non-cancelled SubOrders | |
| Rider earning | 80% of delivery_fee of Delivered deliveries | |
| Ratings | Integers 1 to 5 | |
| CartItem.quantity | Integers 1 to 10 (max 10 per order item) | |

### 2.4 Error Codes

| Code | Meaning |
|---|---|
| 0 | Success (stored procedures only) |
| -1 | Invalid input: a value breaks a constraint or business rule |
| -2 | Duplicate: the value or record already exists |
| -3 | Not allowed: wrong user type, out of scope, not the owner, or Blacklisted |
| -4 | Wrong status: the current status does not allow the action |
| -5 | Zone mismatch: the active address is not in the zone of the business |
| -6 | Limit exceeded (e.g. more than 10 of one product in the cart) |
| -7 | Payment cannot be made |
| -8 | No available rider |
| -9 | Nothing to process (e.g. empty cart or nothing to copy) |

Procedures return the code with `RETURN`. A function returning int or decimal returns the (negative) code instead of its value. Login functions return a bit and return 0 on any error. Table-valued functions return an empty table on any error.

---

## 3. Database Schema (Section 3 merged with Appendix A)

Create the tables **in this order**, with exactly these columns in this column order. PK: primary key, FK: foreign key, NN: NOT NULL (all other non-key columns allow NULL). If Section 3 and Appendix A ever seem to differ, report it on CMS.

### 3.1 Zone
| Column | Type | Constraints |
|---|---|---|
| zone_id | int identity(1,1) | PK |
| zone_name | varchar(50) | NN, UNIQUE |
| delivery_fee | decimal(10,2) | NN, CHECK (delivery_fee >= 0) |

### 3.2 Users
| Column | Type | Constraints |
|---|---|---|
| user_id | int identity(1,1) | PK |
| first_name | varchar(30) | NN |
| middle_name | varchar(30) | |
| last_name | varchar(30) | NN |
| username | varchar(30) | NN, UNIQUE |
| password | varchar(30) | NN |
| email | varchar(100) | NN, UNIQUE |
| dob | date | |
| account_status | varchar(20) | NN, DEFAULT Active |

### 3.3 User_Phone
| Column | Type | Constraints |
|---|---|---|
| user_id | int | PK, FK → Users(user_id) |
| phone | char(11) | PK |

### 3.4 Admin
| Column | Type | Constraints |
|---|---|---|
| admin_id | int | PK, FK → Users(user_id) |
| role | varchar(20) | NN, DEFAULT Super Admin |
| zone_id | int | FK → Zone(zone_id). NULL for Super Admins |

### 3.5 Partner
| Column | Type | Constraints |
|---|---|---|
| partner_id | int | PK, FK → Users(user_id) |

### 3.6 Rider
| Column | Type | Constraints |
|---|---|---|
| rider_id | int | PK, FK → Users(user_id) |
| vehicle_type | varchar(30) | NN |
| plate_no | varchar(15) | NN, UNIQUE |
| license_no | varchar(20) | NN, UNIQUE |
| is_available | bit | NN, DEFAULT 1 |
| zone_id | int | NN, FK → Zone(zone_id) |

### 3.7 Customer
| Column | Type | Constraints |
|---|---|---|
| customer_id | int | PK, FK → Users(user_id) |
| wallet_balance | decimal(10,2) | NN, DEFAULT 0, CHECK (wallet_balance >= 0) |

### 3.8 Address
A customer has exactly one active address (`is_active = 1`); all their other addresses have `is_active = 0`.

| Column | Type | Constraints |
|---|---|---|
| address_id | int identity(1,1) | PK |
| description | varchar(150) | NN |
| is_active | bit | NN, DEFAULT 1 |
| customer_id | int | NN, FK → Customer(customer_id) |
| zone_id | int | NN, FK → Zone(zone_id) |

### 3.9 Card
| Column | Type | Constraints |
|---|---|---|
| card_id | int identity(1,1) | PK |
| card_no | char(16) | NN |
| card_holder_name | varchar(100) | NN |
| expiration_date | date | NN |
| customer_id | int | NN, FK → Customer(customer_id) |

UNIQUE (customer_id, card_no).

### 3.10 Business
| Column | Type | Constraints |
|---|---|---|
| business_id | int identity(1,1) | PK |
| name | varchar(100) | NN |
| description | varchar(255) | |
| link_website | varchar(255) | |
| opening_hour | time | NN |
| closing_hour | time | NN |
| expected_delivery_time | int | NN, minutes, CHECK (expected_delivery_time > 0) |
| status | varchar(20) | NN, DEFAULT Pending |
| suspension_reason | varchar(255) | Only while Suspended |
| partner_id | int | NN, UNIQUE, FK → Partner(partner_id) |
| zone_id | int | NN, FK → Zone(zone_id) |

### 3.11 Business_Phone
| Column | Type | Constraints |
|---|---|---|
| business_id | int | PK, FK → Business(business_id) |
| phone | char(11) | PK |

### 3.12 Restaurant
| Column | Type | Constraints |
|---|---|---|
| business_id | int | PK, FK → Business(business_id) |
| cuisine_type | varchar(50) | NN |
| food_category | varchar(50) | NN |

### 3.13 Pharmacy
| Column | Type | Constraints |
|---|---|---|
| business_id | int | PK, FK → Business(business_id) |
| pharmacy_type | varchar(50) | NN |

### 3.14 Blacklist
A row exists only while the customer is Blacklisted: Blacklist_Customer inserts it, Lift_Customer_Blacklist deletes it. customer_id is the key, so a customer has at most one blacklisting admin; one admin can blacklist many customers (BR-4). Only the admin in admin_id can lift it.

| Column | Type | Constraints |
|---|---|---|
| customer_id | int | PK, FK → Customer(customer_id) |
| admin_id | int | NN, FK → Admin(admin_id) |
| reason | varchar(255) | NN |

### 3.15 Product
| Column | Type | Constraints |
|---|---|---|
| product_id | int identity(1,1) | PK |
| name | varchar(100) | NN |
| description | varchar(255) | |
| category | varchar(50) | NN |
| price | decimal(10,2) | NN, CHECK (price > 0) |
| discount_amount | decimal(10,2) | NN, DEFAULT 0, CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price) |
| is_available | bit | NN, DEFAULT 1 |
| business_id | int | NN, FK → Business(business_id) |

### 3.16 Favorite_Business
| Column | Type | Constraints |
|---|---|---|
| customer_id | int | PK, FK → Customer(customer_id) |
| business_id | int | PK, FK → Business(business_id) |

### 3.17 Favorite_Product
| Column | Type | Constraints |
|---|---|---|
| customer_id | int | PK, FK → Customer(customer_id) |
| product_id | int | PK, FK → Product(product_id) |

### 3.18 Voucher
| Column | Type | Constraints |
|---|---|---|
| voucher_id | int identity(1,1) | PK |
| promo_code | varchar(30) | NN, UNIQUE |
| is_percentage | bit | NN |
| amount | decimal(10,2) | NN, CHECK (amount > 0) |
| expiry_date | date | NN |
| status | varchar(20) | NN, DEFAULT Unused |
| customer_id | int | NN, FK → Customer(customer_id) |

### 3.19 Cart
A customer has at most one Active cart per address (one Active cart for the active address).

| Column | Type | Constraints |
|---|---|---|
| cart_id | int identity(1,1) | PK |
| status | varchar(20) | NN, DEFAULT Active |
| created_at | datetime | NN, DEFAULT GETDATE() |
| customer_id | int | NN, FK → Customer(customer_id) |
| address_id | int | NN, FK → Address(address_id) |

### 3.20 CartItem
| Column | Type | Constraints |
|---|---|---|
| cart_id | int | PK, FK → Cart(cart_id) |
| product_id | int | PK, FK → Product(product_id) |
| quantity | int | NN, CHECK (quantity BETWEEN 1 AND 10) |
| notes | varchar(255) | |
| unit_price | decimal(10,2) | Set at checkout |

### 3.21 Orders
Named Orders because ORDER is a reserved word.

| Column | Type | Constraints |
|---|---|---|
| order_id | int identity(1,1) | PK |
| order_date | datetime | NN |
| status | varchar(20) | NN, DEFAULT Placed |
| discount_amount | decimal(10,2) | NN, DEFAULT 0 |
| total_amount | decimal(10,2) | NN |
| cart_id | int | NN, UNIQUE, FK → Cart(cart_id) |
| zone_id | int | NN, FK → Zone(zone_id) |
| voucher_id | int | FK → Voucher(voucher_id) |

### 3.22 SubOrder
| Column | Type | Constraints |
|---|---|---|
| suborder_id | int identity(1,1) | PK |
| status | varchar(20) | NN, DEFAULT Placed |
| total_price | decimal(10,2) | NN |
| delivery_fee | decimal(10,2) | NN |
| order_id | int | NN, FK → Orders(order_id) |
| business_id | int | NN, FK → Business(business_id) |

UNIQUE (order_id, business_id).

### 3.23 Delivery
| Column | Type | Constraints |
|---|---|---|
| delivery_id | int identity(1,1) | PK |
| assigned_at | datetime | NN |
| picked_up_at | datetime | |
| delivered_at | datetime | |
| tracking_time | int | Minutes from pickup to delivery |
| rider_rating | int | CHECK (rider_rating BETWEEN 1 AND 5) |
| suborder_id | int | NN, UNIQUE, FK → SubOrder(suborder_id) |
| rider_id | int | NN, FK → Rider(rider_id) |

### 3.24 Payment
| Column | Type | Constraints |
|---|---|---|
| payment_id | int identity(1,1) | PK |
| amount | decimal(10,2) | NN |
| currency | varchar(3) | NN, DEFAULT EGP |
| method | varchar(20) | NN |
| transaction_date | datetime | NN |
| refunded_amount | decimal(10,2) | NN, DEFAULT 0, CHECK (refunded_amount <= amount) |
| order_id | int | NN, UNIQUE, FK → Orders(order_id) |
| card_id | int | FK → Card(card_id) |

### 3.25 Feedback
| Column | Type | Constraints |
|---|---|---|
| feedback_id | int identity(1,1) | PK |
| headline | varchar(100) | NN |
| description | varchar(500) | |
| rating | int | NN, CHECK (rating BETWEEN 1 AND 5) |
| feedback_date | datetime | NN, DEFAULT GETDATE() |
| suborder_id | int | NN, UNIQUE, FK → SubOrder(suborder_id) |

---

## 4. Requirements

Format: **Name** — Type. Input → Output. All "Output: Nothing" procedures still return the Section 2.4 code.

### 4.1 Basic Structure of the Database
- a) **LocalDeliveryMarketplace_Team_XX** — SQL statement. Create the database (XX = team number).
- b) **createAllTables** — SP. Create all tables of Section 3 with the types/constraints of Appendix A. No input/output.
- c) **dropAllTables** — SP. Drop all tables in an order respecting the FKs.
- d) **dropAllProceduresFunctionsViews** — SP. Drop all procedures (except this one), functions and views, including helpers.
- e) **clearAllTables** — SP. Delete all records and reset every identity so the next ID is 1. (Tests guide: afterwards every table is empty, the next zone inserted gets zone_id 1 and the next user gets user_id 1.)

### 4.2 Basic Data Retrieval
- a) **allBusinessProfiles** — View. All businesses (any status) with their partner; partner_name = first name + ' ' + last name. → (business_id, business_name, business_type, zone_name, partner_name, status, opening_hour, closing_hour)
- b) **BusinessesPerZone** — View. Number of Active businesses per zone, including zones with 0. → (zone_id, zone_name, business_count)
- c) **BusinessRatingsSummary** — View. Average rating and number of feedbacks of every business (NULL and 0 if none). → (business_id, business_name, avg_rating, ratings_count)
- d) **ActiveVouchers** — View. Vouchers not expired and not used yet. → (voucher_id, promo_code, customer_id, is_percentage, amount, expiry_date)
- e) **PendingBusinessApprovals** — View. Businesses awaiting approval (Pending). → (business_id, business_name, business_type, zone_name, partner_name)
- f) **RiderPerformanceSummary** — View. Every rider with number of Delivered deliveries (0 if none) and average rider rating (NULL if none). → (rider_id, rider_name, zone_name, completed_deliveries, avg_rating)
- g) **[Hard] TopSellingProducts** — View. Top 10 products by units sold over non-cancelled SubOrders (ties: smallest product_id). total_revenue = Σ quantity × unit_price. → (product_id, product_name, business_name, business_type, units_sold, total_revenue)
- h) **ZoneDeliveryPerformance** — View. Per zone (the order's zone): number of Delivered deliveries and their average tracking_time, including zones with none (0 and NULL). → (zone_id, zone_name, delivery_count, avg_tracking_time)

### 4.3 Accounts: Registration, Login and Password
Common registration inputs below = `first_name varchar(30), middle_name varchar(30), last_name varchar(30), username varchar(30), password varchar(30), email varchar(100), phone char(11), dob date`.
- a) **Customer_Register** — SP. Register a customer (wallet_balance 0). Input: common registration inputs.
- b) **Partner_Register** — SP. Register a partner (business registered later in 4.5.a). Input: common registration inputs.
- c) **Rider_Register** — SP. Register an available rider in a zone. Input: common registration inputs, `vehicle_type varchar(30), plate_no varchar(15), license_no varchar(20), zone_id int`.
- d) **CustomerLoginValidation** — scalar function. Returns 1 only if credentials match a customer with an Active account, else 0. Input: `username varchar(30), password varchar(30)` → success bit.
- e) **PartnerLoginValidation** — scalar function, same rules as d. Same input → success bit.
- f) **RiderLoginValidation** — scalar function, same rules. Same input → success bit.
- g) **AdminLoginValidation** — scalar function, same rules. Same input → success bit.
- h) **Change_Password** — SP. Change the password of any user; success = 1 if changed, else 0 and nothing changes. Input: `user_id int, old_password varchar(30), new_password varchar(30), new_password_repeat varchar(30), success bit OUTPUT`.

### 4.4 As an Admin
- a) **Create_Admin** — SP, Super Admin only. A NULL role means Super Admin. Input: common registration inputs, `role varchar(20), zone_id int, super_admin_id int`.
- b) **Approve_Business** — SP, Super Admin or Zone Admin (own zone only, BR-3). Pending → Active. Rejected if a Zone Admin isn't assigned to the business's zone; a Super Admin can approve any. Input: `business_id int, admin_id int`.
- c) **Reject_Business** — SP, same scope as b. Pending → Rejected. Input: `business_id int, admin_id int`.
- d) **[Hard] Suspend_Business** — SP, Super Admin or Zone Admin (own zone, BR-3). Input: `business_id int, admin_id int, reason varchar(255)`.
  - Reject if the business isn't Active or the admin is out of scope (BR-3).
  - Set status Suspended, store the reason, set `is_available = 0` on all its products.
  - Cancel each of its Placed or Assigned SubOrders, refund it (BR-14) and recompute the order status (BR-11). If this cancels every SubOrder of an order, restore the order's voucher as in Cancel_Order.
- e) **[Hard] Reinstate_Business** — SP, Super Admin only (whoever suspended it). Status becomes Active, suspension_reason cleared; all products stay unavailable until the partner re-enables them. Input: `business_id int, super_admin_id int`.
- f) **Create_Zone** — SP, Super Admin only. Input: `zone_name varchar(50), delivery_fee decimal(10,2), super_admin_id int`.
- g) **Update_Zone_Fee** — SP, Super Admin only. Existing SubOrders keep their own fee. Input: `zone_id int, new_fee decimal(10,2), super_admin_id int`.
- h) **Assign_Admin_Zone** — SP, Super Admin only. Assign or move a Zone Admin to a zone. Input: `admin_id int, zone_id int, super_admin_id int`.
- i) **Issue_Voucher** — SP, Super Admin or Zone Admin. Reject if the customer is Blacklisted, the promo code exists, or any validation/business rule is violated. Input: `customer_id int, promo_code varchar(30), is_percentage bit, amount decimal(10,2), expiry_date date, admin_id int`.
- j) **[Hard] Blacklist_Customer** — SP, Super Admin or Zone Admin (Zone Admin only for customers with an address in their zone, BR-3). Input: `customer_id int, admin_id int, reason varchar(255)`.
  - Reject if already Blacklisted.
  - Set account_status Blacklisted and insert into Blacklist with admin and reason (BR-4).
  - Cancel all the customer's orders that Cancel_Order would accept, then delete all their Unused vouchers.
- k) **Lift_Customer_Blacklist** — SP. Only the admin stored in `Blacklist.admin_id` can lift it; reject any other admin. Account becomes Active and the customer is removed from Blacklist. Deleted vouchers aren't restored. Input: `customer_id int, admin_id int`.
- l) **ZoneOrderReport** — TVF, Super Admin or Zone Admin. For a zone and date range: number of non-cancelled orders, their average total_amount, and platform commission on them. Input: `zone_id int, from_date date, to_date date` → (zone_id, zone_name, number_of_orders, avg_order_total, platform_commission)
- m) **TopRiders** — TVF, Super Admin or Zone Admin. Top 5 riders by deliveries delivered in a period (ties: smallest rider_id); rider_rank 1–5; riders with none excluded. Input: `from_date date, to_date date` → (rider_rank, rider_id, rider_name, completed_delivery_count)
- n) **Daily_Revenue_Report** — TVF, Super Admin or Zone Admin. Revenue of one day per zone and business type, over non-cancelled SubOrders of orders placed that day. Input: `report_date date` → (zone_name, business_type, number_of_suborders, gross_sales, delivery_fees, platform_commission)

### 4.5 As a Partner
- a) **Register_Business** — SP. Starts Pending. A partner owns at most one business. If the partner's business was Rejected, registering again doesn't create a second one: the Rejected business gets the new data (its phones and its Restaurant/Pharmacy row are replaced) and returns to Pending. A Restaurant needs cuisine_type and food_category; a Pharmacy needs pharmacy_type (unused inputs NULL). cuisine_type = cooking style (Egyptian, Italian, Chinese, Lebanese…); food_category = kind of meal mainly served regardless of cuisine (Fast Food, Grills, Seafood, Pizza, Desserts…; an Italian restaurant can have food_category Pizza); pharmacy_type = kind of pharmacy (Retail, Hospital, Online…). Input: `partner_id int, name varchar(100), description varchar(255), link_website varchar(255), zone_id int, opening_hour time, closing_hour time, expected_delivery_time int, phone char(11), business_type varchar(20), cuisine_type varchar(50), food_category varchar(50), pharmacy_type varchar(50)`.
- b) **Update_Business_Info** — SP. Update operating hours and website, and add a phone number. Input: `business_id int, opening_hour time, closing_hour time, phone char(11), link_website varchar(255)`.
- c) **Upsert_Product** — SP. Add a product (product_id NULL) or update one of mine. Reject if the business is Suspended or the product isn't mine. Input: `business_id int, product_id int, name varchar(100), description varchar(255), category varchar(50), price decimal(10,2), is_available bit`.
- d) **Toggle_Product_Status** — SP. Deactivate/reactivate a product. Inactive products are hidden from customers but stay in sales history. Reject reactivation while the business is Suspended. Input: `product_id int, is_available bit`.
- e) **Set_Product_Promotion** — SP. Set a product discount amount (0 removes it). Input: `product_id int, discount_amount decimal(10,2)`.
- f) **BusinessSalesReport** — TVF. Units sold and revenue per product of my business for orders placed in a date range (non-cancelled SubOrders, sold products only). Input: `business_id int, from_date date, to_date date` → (product_id, product_name, units_sold, revenue_per_product)
- g) **BusinessFeedbackOverview** — TVF. My average rating, number of feedbacks and count per star. Input: `business_id int` → (avg_rating, number_of_feedbacks, five_star, four_star, three_star, two_star, one_star)

### 4.6 As a Customer
- a) **Add_Customer_Address** — SP. Add a new address; it becomes active and all others inactive. Input: `customer_id int, description varchar(150), zone_id int`.
- b) **Update_Delete_Customer_Address** — SP. Update (description and zone) or delete one of my addresses. Reject if not mine or it belongs to a Placed or In Progress order. Also reject Delete if used by any cart. Input: `customer_id int, address_id int, description varchar(150), zone_id int, action varchar(20)`.
- c) **Change_Active_Address** — SP. Set the selected address as active, only one active at a time. Reject if not the customer's. New carts and orders use the active address; carts linked to other addresses stay saved but unavailable until their address becomes active again. Input: `customer_id int, new_address_id int`.
- d) **Add_Card** — SP. Save a card. Input: `customer_id int, card_no char(16), card_holder_name varchar(100), expiration_date date`.
- e) **Create_Cart** — SP. Create an empty cart for my active address (picked automatically). Reject if Blacklisted, no active address, or the active address already has an Active cart. Input: `customer_id int`.
- f) **Add_To_Cart** — SP. Add a product with a quantity and optional note to my Active cart (the cart of my active address). If already there, add to its quantity and replace the note if a new one is given. Reject (with an error) if the cart's address isn't my active address or the product's business isn't in the zone of my active address. Reject if the resulting quantity would exceed 10. Input: `cart_id int, product_id int, quantity int, notes varchar(255)`.
- g) **Remove_From_Cart** — SP. Remove a product from one of my Active carts. Input: `cart_id int, product_id int`.
- h) **Calculate_Voucher_Discount** — scalar function. Discount of a voucher on a subtotal (BR-13), or 0 if the voucher is NULL, missing, not Unused or expired. Doesn't change the voucher. Input: `voucher_id int, order_subtotal decimal(10,2)` → discount decimal(10,2).
- i) **[Hardest!] Checkout_Cart** — SP. Checkout a cart into an order as one atomic unit. Input: `cart_id int, voucher_id int (nullable), payment_method varchar(20), card_id int (nullable)`.
  - Reject the whole checkout if: the cart isn't Active or is empty; the customer is Blacklisted; the cart address isn't the customer's active address (order always goes to the active address; no address input); any product is unavailable, from a non-Active business, outside the active address's zone (zone-mismatch code) or closed now (BR-6); the voucher isn't valid; the payment can't be made.
  - Payment (BR-10): one method for the whole order. Card needs a valid card_id of the customer; Wallet needs enough balance; Cash needs nothing.
  - Copy each effective unit price into `CartItem.unit_price`, create the order (zone of the address), and create one SubOrder per business (not per business type) with its total_price and delivery_fee. The order starts Placed (BR-11).
  - Compute and store discount_amount (via Calculate_Voucher_Discount) and total_amount. Mark the voucher Used.
  - Create one Delivery per SubOrder and set each SubOrder to Assigned.
  - Create the Payment, deduct total_amount from the wallet if method is Wallet, set the cart to Checked Out.
- j) **[Hard] Cancel_Order** — SP. Cancel an order before anything is picked up. Input: `order_id int`.
  - Reject if the order is Cancelled or any SubOrder is Picked Up or Delivered.
  - Cancel all remaining SubOrders (and so their Deliveries) and the order, refund the remaining amount (BR-14).
  - If a voucher was used, set it back to Unused and set the order's voucher_id to NULL.
- k) **Reorder** — SP. Create a new Active cart with the same products, quantities and notes as a past order, skipping products that can no longer be ordered, for an address I choose. The address must be mine and in the same zone as the original order; if it isn't my active address it becomes my active address. Reject if Blacklisted, the address isn't mine or is in a different zone from the order, the address already has an Active cart (BR-8), or nothing can be copied. Input: `order_id int, address_id int`.
- l) **Submit_Feedback** — SP. Leave one feedback for a Delivered SubOrder. Input: `suborder_id int, headline varchar(100), description varchar(500), rating int`.
- m) **Rate_Rider** — SP. Rate once the rider of a Delivered SubOrder (stored in `Delivery.rider_rating`). Input: `suborder_id int, rider_rating int`.
- n) **My_Order_History** — TVF. Input: `customer_id int` → (order_id, order_date, zone_name, status, number_of_suborders, discount_amount, total_amount, payment_method, refunded_amount)
- o) **Toggle_Favorite** — SP. Add a business or product to favorites, or remove it if already there. Input: `customer_id int, item_id int, item_type varchar(20)`.
- p) **My_Favorites** — TVF. The customer's favorite products only; is_orderable = 1 if the product can be ordered now (BR-5). Input: `customer_id int` → (product_id, product_name, business_name, is_orderable)
- q) **[Hard] Recommended_Products** — TVF. Up to 10 available products from Active businesses serving the customer's active address. Only products the customer has never ordered and whose categories the customer has ordered from before. Prioritize the customer's most-ordered categories, ties by smallest product_id. Input: `customer_id int` → (product_id, product_name, business_name, category, final_price)

### 4.7 As a Rider
- a) **Set_Rider_Availability** — SP. Unavailable riders keep current deliveries but get no new ones. Input: `rider_id int, is_available bit`.
- b) **My_Active_Deliveries** — TVF. status is the SubOrder status. Input: `rider_id int` → (delivery_id, order_id, suborder_id, business_name, customer_name, address_description, zone_name, status, assigned_at)
- c) **Mark_Picked_Up** — SP. Mark an Assigned delivery Picked Up (SubOrder Assigned → Picked Up), stamp picked_up_at, recompute the order status. Input: `delivery_id int`.
- d) **Mark_Delivered** — SP. Mark a Picked Up delivery Delivered (SubOrder Picked Up → Delivered), stamp delivered_at, store tracking_time in minutes since pickup, recompute the order status. Input: `delivery_id int`.
- e) **My_Earnings** — TVF. Earnings for deliveries delivered in a date range. Input: `rider_id int, from_date date, to_date date` → (completed_deliveries, total_delivery_fees, total_earnings)
- f) **My_Rating_Summary** — TVF. Average rider rating, number of ratings, count per star. Input: `rider_id int` → (avg_rating, ratings_count, five_star, four_star, three_star, two_star, one_star)
- g) **My_Delivery_History** — TVF. My Delivered and Cancelled deliveries assigned in a date range (status is the SubOrder status). Input: `rider_id int, from_date date, to_date date` → (delivery_id, order_id, business_name, status, assigned_at, picked_up_at, delivered_at, tracking_time)

### 4.8 System-Level Requirements
- a) **[Hard] Search_Platform** — TVF. Search Active businesses by name with the keyword, only those serving the customer's active address, ranked: 1 exact match, 2 name starts with keyword, 3 name contains keyword. Include priority and sort ascending by it. Input: `customer_id int, keyword varchar(100)` → (business_id, business_name, priority)
- b) **[Hard] Reconcile_Order_Totals** — TVF. Every order whose total_amount differs from Σ(SubOrder total_price + delivery_fee) (cancelled included) − discount_amount, whose payment amount differs from total_amount, or that has no payment. Fix nothing. No input → (order_id, expected_total, order_total, payment_amount)
- c) **Nearby_Businesses_By_Category** — TVF. Active businesses with at least one available product in a category. same_zone = 1 for the address zone. zone_avg_delivery_time = average tracking_time of Delivered deliveries in the business zone. Rank by same_zone desc, then zone_avg_delivery_time. Input: `address_id int, product_category varchar(50)` → (business_id, business_name, zone_name, same_zone, zone_avg_delivery_time)
- d) **Platform_Health_Snapshot** — TVF. Dashboard: Active businesses, available riders, orders placed today, average tracking_time of today's deliveries, feedbacks rated ≤ 2 today. No input → (active_businesses, available_riders, orders_today, avg_delivery_time_today, low_ratings_today)

---

## 5. Work Split (mandatory)

Five areas of comparable effort. Three students get two hard requirements; Students 1 and 5 get one plus more regular items. Student 3 has fewer items because Checkout_Cart is the largest. **Student 4 should create the tables first so everyone can test.**

| Student / area | Hard | Other requirements |
|---|---|---|
| 1: Accounts and admin governance | Blacklist_Customer | Customer_Register, Partner_Register, Rider_Register, the 4 login functions, Change_Password, Create_Admin, Approve_Business, Reject_Business, Assign_Admin_Zone, Issue_Voucher, Lift_Customer_Blacklist, ActiveVouchers, Detect_Voucher_Abuse |
| 2: Partners and catalog | Search_Platform, TopSellingProducts | Register_Business, Update_Business_Info, Upsert_Product, Toggle_Product_Status, Set_Product_Promotion, BusinessSalesReport, allBusinessProfiles, PendingBusinessApprovals, Nearby_Businesses_By_Category, Toggle_Favorite, My_Favorites, Recommended_Products |
| 3: Shopping and ordering | Checkout_Cart, Cancel_Order | Add_Customer_Address, Update_Delete_Customer_Address, Add_Card, Create_Cart, Add_To_Cart, Remove_From_Cart, Change_Active_Address, Calculate_Voucher_Discount, Reorder, My_Order_History |
| 4: Database, zones and business moderation | Suspend_Business, Reinstate_Business | Database statement, createAllTables, dropAllTables, dropAllProceduresFunctionsViews, clearAllTables, Create_Zone, Update_Zone_Fee, BusinessesPerZone, ZoneOrderReport, Daily_Revenue_Report |
| 5: Riders, ratings and monitoring | Reconcile_Order_Totals, Recommended_Products | Set_Rider_Availability, My_Active_Deliveries, Mark_Picked_Up, Mark_Delivered, My_Earnings, My_Rating_Summary, RiderPerformanceSummary, ZoneDeliveryPerformance, TopRiders, Submit_Feedback, Rate_Rider, BusinessRatingsSummary, BusinessFeedbackOverview, Platform_Health_Snapshot, My_Delivery_History |

Note: the revised PDF lists Recommended_Products both as a Hard item for Student 5 and as an "Other" item for Student 2 (see Transcription notes at the top). Confirm on CMS which student owns it.

---

## 6. Public Tests

Source: `tests/Milestone 2, Public Tests Guide.pdf`. The files in `tests/`:

| File | What it is |
|---|---|
| `grader.py` | Public test grader. Rebuilds the database from `Team_XX.sql`, runs the public tests and prints PASS/FAIL per test. |
| `public_tests.sql` | The 109 public tests the grader runs. Must sit next to `grader.py`. |
| `seed_data.sql` | Sample data every test starts from (zones, users, businesses, orders, ...). Only needed for manual testing. |
| `Milestone 2, Public Tests Guide.pdf` | How to run the grader, plus the expected input and output of every public test. |

Passing every public test does not guarantee full marks: the TAs also run private tests.

### 6.1 Way 1: Run the grader
- **One-time setup:** Python 3 on PATH, `pip install pyodbc`, SQL Server 2019 or later running (2019 recommended; its ODBC driver comes with it).
- **Run:** the guide says to put `grader.py`, `public_tests.sql` and `Team_XX.sql` in the same folder. Close any Visual Studio connection to the database, then run `python grader.py Team_28.sql`. If the server isn't found, pass its name as shown in SQL Server Object Explorer: `python grader.py Team_28.sql --server "(localdb)\MSSQLLocalDB"`. It takes about one minute. In this repo the submission is in the root and the test files are in `tests/`.
- **Warning:** the grader **drops `LocalDeliveryMarketplace_Team_XX` and rebuilds it from the file**, exactly like a fresh server. The `.sql` file itself is not changed.
- **Output:** first whether the file ran without errors, then one line per test (`PU-4.4.f-1  PASS  Create_Zone creates a zone`), with the expected-vs-actual reason under each FAIL. It ends with `PASSED N of 109 public tests.` The full report goes to `Team_XX_results.txt` next to the `.sql` file.
- **Test IDs:** `PU-<requirement>-<n>` is test n of that requirement (e.g. `PU-4.4.f-2` is test 2 of 4.4.f; a requirement with one test is just `PU-4.2.a`). `PP-1` to `PP-4` are path tests that chain several requirements the way a real user would. Every test starts again from the seed data, so the grader can be re-run any number of times.

### 6.2 Common grader messages

| Message | What to do |
|---|---|
| Your file raised N error(s) | The file must run top to bottom without errors. Fix the line shown. |
| FIX THIS FIRST: the seed data does not fit your tables | A table or column name, order or type differs from Section 3 / Appendix A. Fix the tables first; most tests fail until then. |
| the call raised an error instead of returning -3 | Return the error code with `RETURN`. Don't raise an error. |
| expected return code -4 but got -1 | Wrong error code. Check Section 2.4 and the test's table in the guide. |
| the rejected call changed the database | An error code was returned after some rows had already changed. Check everything before any insert/update/delete. |
| expected columns (...) but got (...) | A view/function's output columns have different names or order. |
| expected 3 row(s), got 2. Missing rows: ... | Output differs. Compare with the test's Expected output table in the guide. |
| Could not connect to SQL Server | Start SQL Server, or pass `--server` with the name shown in Visual Studio. |
| pyodbc is not installed | `pip install pyodbc`. |

### 6.3 Way 2: Manual checks against expected input/output
1. Run `Team_XX.sql`.
2. Empty the tables: `EXEC clearAllTables;`
3. Run `seed_data.sql` (replace `XX` in its `USE` line with the team number).
4. Call the procedure/function with the values of one case and compare with the guide's tables.
5. Reload the seed data (steps 2 and 3) before the next test.

How the guide's per-test tables read:
- **Input / Case 1, Case 2, ...:** one column per call; each row is a parameter, in description order. `NULL` means pass NULL.
- **Returns:** the procedure's return value (0 success, negative = error code) or the function's return value.
- **Tables after the call:** "No change" means every table must stay exactly as it was. For a successful call, the listed table/row/column values must hold.
- **Expected output:** for views and TVFs, the exact column names in order, and the rows to return (rows compared in any order).

The per-test expected inputs and outputs (guide Section 3, grouped by requirement 4.2 to 4.8) are not transcribed here. Look up a test ID in the guide when needed.

### 6.4 Implications for the implementation
- Errors are reported only via `RETURN <code>`. A `RAISERROR`/`THROW` where a code is expected fails the test.
- Validate everything before the first write, so that rejected calls leave every table untouched.
- Output column names and order are checked exactly. Row order isn't.
- Step 1 of Way 2 goes straight to `EXEC clearAllTables` after running the file, which implies the tables must already exist once `Team_XX.sql` has run. So the file should `EXEC dbo.createAllTables;` itself (this is also needed before the first view; see `AGENTS.md`).
