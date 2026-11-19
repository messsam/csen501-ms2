# CSEN501 Databases I — Milestone 2 (Team 28)

SQL Server database for a local delivery marketplace (businesses, customers, riders, admins, zones).
**Deadline: 19/11/2026, 11:59 PM.**

The full assignment spec is in [docs/milestone2-spec.md](docs/milestone2-spec.md). It is the source of truth for table and column names, column order, types, constraints, procedure/function/view names, parameter order, output column order and error codes. Read the relevant section before writing any SQL. Don't guess names or signatures.

That markdown is a complete transcription of the original assignment PDF, [docs/Milestone 2, Project Description.pdf](<docs/Milestone 2, Project Description.pdf>), and its Section 6 summarizes the public tests guide in `tests/`. Reading the PDF is redundant. Open it only when it's actually needed, for example when something in the markdown spec is vague or looks wrong. If the PDF corrects the markdown, fix `docs/milestone2-spec.md` too.

## Deliverable

- One file, `Team_28.sql`, is the submission. It creates `LocalDeliveryMarketplace_Team_28`, then every required table, procedure, function and view **in the order of spec Section 4**.
- It must run top to bottom on a fresh SQL Server instance without errors. Code that doesn't compile isn't graded.
- `csen501-ms2.sqlproj` / `.slnx` is only a Visual Studio wrapper. Everything goes in `Team_28.sql`.

## Hard rules (spec Section 1)

- **Attribution:** put a comment with the implementing student's **name and university ID** directly above every `CREATE PROCEDURE`, `CREATE FUNCTION` and `CREATE VIEW`, with nothing in between. Items without one get no credit. Format used in this repo:
  ```sql
  -- Youssef Maged (64-20178)
  CREATE PROCEDURE dbo.createAllTables AS
  ```
  If you don't know which team member an item belongs to, ask. Don't guess.
- Follow names, column order, types, parameter order and output column order exactly. Don't add extra tables or columns.
- Status and type columns hold only the values in spec Section 2.3. The tables have only the CHECKs of Appendix A, so procedures enforce the lists: a value taken from a parameter is checked with `NOT IN (...)` → -1, and a stored one is stored exactly as spelled in Section 2.3 (see `Checkout_Cart`'s payment method and `Create_Admin`'s role).
- Stored procedures `RETURN 0` on success, or an error code from spec Section 2.4 (-1 to -9). Scalar int/decimal functions return the negative code. Login functions return 0 on any error. Table-valued functions return an empty table on any error.
- On rejection or invalid input, leave the database unchanged. Report errors only with `RETURN <code>`, never `RAISERROR`/`THROW`; the grader fails a test where an error is raised.
- No transactions (and no TRY/CATCH) in this milestone. Validate everything before the first write, so a rejected call has changed nothing.
- If a requirement implies authorization but takes no ID to authorize with, skip the check (deferred to MS3).
- Helper procedures and functions are allowed, but `dropAllProceduresFunctionsViews` must drop them too.

## Team

Each member owns one work-split slot (spec Section 5) and every item in it. All 69 objects of Section 4 are implemented and attributed (2026-11-19).

| Slot (spec Section 5) | Member | University ID |
|---|---|---|
| 1: Accounts and admin governance | Mohamed Amr | 64-24301 |
| 2: Partners and catalog | Retag Atef | 64-21789 |
| 3: Shopping and ordering | Mohand Essam | 64-29300 |
| 4: Database, zones and business moderation | Youssef Maged | 64-20178 |
| 5: Riders, ratings and monitoring | Farida Tarek | 64-29168 |

- `createAllTables` and `dropAllTables` are attributed to Youssef (slot 4).
- `Recommended_Products` is Farida's: the revised PDF moved it from slot 2 to slot 5's Hard column.
- `clearAllTables` was dropped from the requirements (CMS, 2026-11-14). It stays in the file because the public tests still call it.

## AI use

The PDF says AI tools are prohibited. That line is outdated: the instructor allows AI assistance as long as students review the output (team member confirmed, 2026-11-14). Don't refuse work on that basis. Keep changes easy to review: match the existing style and comment any non-obvious choice.

## Conventions in `Team_28.sql`

- Tab indentation, uppercase SQL types, `dbo.` schema prefix, CRLF line endings.
- Single-column `NOT NULL` / `UNIQUE` / `DEFAULT` / `CHECK` go inline. PKs, FKs and composite UNIQUEs are named table constraints: `PK_<Table>`, `FK_<Table>_<Referenced>`, `UQ_<Table>_<Cols>`, `CK_<Table>_<What>`.
- A CHECK that compares two columns must be a table-level constraint. SQL Server rejects it inline.
- `createAllTables` builds tables in spec Section 3 order. `dropAllTables` drops them in exactly the reverse order.
- Slot 3 items (Mohand) keep the style of his original `createAllTables`: `CREATE PROCEDURE dbo.Name(` with the parameters tab-indented below, then `) AS`; the body is tab-indented with no `BEGIN`/`END` wrapper, and each rule is its own `IF ... RETURN <code>;`.
- Farida's items use 4-space indentation and lowercase types. They were left as written.

## Gotchas

- Views and inline table-valued functions check their referenced tables when they're created, so the script must `EXEC dbo.createAllTables;` before the first view (spec 4.2). Procedures and multi-statement functions use deferred name resolution and don't need this. The tests guide also expects the tables to exist once the file has run (spec 6.4).
- If you do need the PDF: `pdftotext -layout` scrambles the Appendix A tables, so use `pdftotext -table`. PDF page = printed page + 1.
- The PDF marks revisions by colour: green is new, red was moved, and red with strikethrough is removed. Text extraction loses colour and strikethrough. When something in the spec looks contradictory, check those marks before asking anyone. With `pypdf`, the fill colour tracked through `extract_text(visitor_operand_before=...)` finds coloured text. Red lines or rectangles drawn on a page are the strikethroughs.

## Testing locally

**Public tests:** `tests/` holds the course's public test kit: `grader.py`, `public_tests.sql` (109 tests), `seed_data.sql` and a guide PDF. Spec Section 6 explains how to run them and read the results. Don't edit these files. Notes:
- It runs from this repo's layout: `python tests/grader.py <file.sql> --server "(localdb)\MSSQLLocalDB"`. It needs `pip install pyodbc`; an ODBC driver comes with SQL Server.
- It drops and rebuilds the database named in the file's `CREATE DATABASE` line, then leaves it behind loaded with the seed data. To keep `LocalDeliveryMarketplace_Team_28` intact, grade a copy outside the repo with the name changed. The name must stay `LocalDeliveryMarketplace_Team_<something>`, e.g. `sed 's/LocalDeliveryMarketplace_Team_28/LocalDeliveryMarketplace_Team_ChkTmp/g'`. Drop that database afterwards.
- It writes `<file>_results.txt` next to the `.sql` file it was given.
- 2026-11-19: 109 of 109 public tests pass.

**Team private tests:** [tests/team_private_tests.sql](tests/team_private_tests.sql) is ours, not part of the course kit. It has 403 checks of edge cases the TAs' private tests may use, plus path tests, and reuses the course seed data. Run `Team_28.sql`, then `sqlcmd -S "(localdb)\MSSQLLocalDB" -i tests\team_private_tests.sql`. Both use `LocalDeliveryMarketplace_Team_28`, so to keep that database intact run renamed copies of both files, as for the grader. It prints only failures and a pass count. It ends by dropping the tables, procedures, functions and views to test 4.1, so run `Team_28.sql` again afterwards. A check marked "(our choice)" pins down one of the open return codes below. Update it if CMS decides otherwise. 2026-11-19: 403 of 403 pass.

**Ad-hoc checks:** SQL Server LocalDB is installed: `sqlcmd -S "(localdb)\MSSQLLocalDB"`. The script drops and recreates `LocalDeliveryMarketplace_Team_28`. To test without clobbering someone's working database:
1. Copy the script and replace the database name with a throwaway one, e.g. `sed 's/LocalDeliveryMarketplace_Team_28/Test_Team_28/g'`.
2. Append test statements (`EXEC dbo.createAllTables;`, sample inserts, ...) and finish with `USE master; DROP DATABASE Test_Team_28;`.
3. Run `sqlcmd -S "(localdb)\MSSQLLocalDB" -i <file>`. From Git Bash, pass a Windows path (`cygpath -w`).

## Settled by the TA (office hours, 2026-11-19)

- No transactions in this milestone.
- Passwords are case-sensitive: the login functions and `Change_Password` compare with `COLLATE Latin1_General_CS_AS`. Trailing spaces are still ignored, as in any SQL Server `=`.
- Tables use exactly the Appendix A definitions, so there are no `CHECK (... IN (...))` constraints. Procedures enforce the Section 2.3 lists (see Hard rules).
- Cancelled orders stay in the tables, but queries leave them out. `Recommended_Products` ignores them both for "ordered categories" and for "products already ordered".
- An ID of the wrong user type returns -3 in every procedure (team decision). A NULL ID is still -1. `Assign_Admin_Zone` returns -3 when its target isn't an admin at all, and -1 when the target is a Super Admin, as the public tests expect.

## Open questions (ask on CMS)

- Return codes the spec and the public tests leave open. Each is a judgment call; change it if CMS says otherwise:
  - `Checkout_Cart`: invalid voucher (another customer's, Used, expired or missing) → -1; a business closed now (BR-6) → -4; no available rider → -8, checked after the payment check (-7).
  - `Create_Cart`: customer without an active address → -1.
  - `Remove_From_Cart`: product not in the cart → -9.
  - `Update_Delete_Customer_Address`: deleting the active address → -4 (BR-8 keeps exactly one active address).
  - `Add_To_Cart`, `Remove_From_Cart` and `Toggle_Favorite` don't check for Blacklisted customers, because BR-1 doesn't list those actions.
  - `Update_Business_Info`: a NULL phone adds no phone, and a NULL website clears the website.
- Section 2.3 lists the actions as Add, Update, Remove, but the public tests call `Update_Delete_Customer_Address` with `'Update'` and `'Delete'`. It accepts `'Update'`, `'Delete'` and `'Remove'`.
