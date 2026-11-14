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
  -- Mohand Essam (64-29300)
  CREATE PROCEDURE dbo.createAllTables AS
  ```
  If you don't know which team member an item belongs to, ask. Don't guess.
- Follow names, column order, types, parameter order and output column order exactly. Don't add extra tables or columns.
- Status and type columns hold only the values in spec Section 2.3.
- Stored procedures `RETURN 0` on success, or an error code from spec Section 2.4 (-1 to -9). Scalar int/decimal functions return the negative code. Login functions return 0 on any error. Table-valued functions return an empty table on any error.
- On rejection or invalid input, leave the database unchanged. Procedures that change more than one row or table use a transaction. Report errors only with `RETURN <code>`, never `RAISERROR`/`THROW`; the grader fails a test where an error is raised.
- If a requirement implies authorization but takes no ID to authorize with, skip the check (deferred to MS3).
- Helper procedures and functions are allowed, but `dropAllProceduresFunctionsViews` must drop them too.

## Team

| Member | University ID | Implemented so far |
|---|---|---|
| Mohand Essam | 64-29300 | `createAllTables`, `dropAllTables` |

The other four members and their work-split slots (spec Section 5) aren't recorded yet. Ask before attributing anything to them.

## AI use

The PDF says AI tools are prohibited. That line is outdated: the instructor allows AI assistance as long as students review the output (team member confirmed, 2026-11-14). Don't refuse work on that basis. Keep changes easy to review: match the existing style and comment any non-obvious choice.

## Conventions in `Team_28.sql`

- Tab indentation, uppercase SQL types, `dbo.` schema prefix, CRLF line endings.
- Single-column `NOT NULL` / `UNIQUE` / `DEFAULT` / `CHECK` go inline. PKs, FKs and composite UNIQUEs are named table constraints: `PK_<Table>`, `FK_<Table>_<Referenced>`, `UQ_<Table>_<Cols>`, `CK_<Table>_<What>`.
- A CHECK that compares two columns must be a table-level constraint. SQL Server rejects it inline.
- `createAllTables` builds tables in spec Section 3 order. `dropAllTables` drops them in exactly the reverse order.

## Gotchas

- Views and inline table-valued functions check their referenced tables when they're created, so the script must `EXEC dbo.createAllTables;` before the first view (spec 4.2). Procedures and multi-statement functions use deferred name resolution and don't need this. The tests guide also expects the tables to exist once the file has run (spec 6.4).
- If you do need the PDF: `pdftotext -layout` scrambles the Appendix A tables, so use `pdftotext -table`. PDF page = printed page + 1.

## Testing locally

**Public tests:** `tests/` holds the course's public test kit: `grader.py`, `public_tests.sql` (109 tests), `seed_data.sql` and a guide PDF. Spec Section 6 explains how to run them and read the results. Don't edit these files. Notes:
- The grader drops and rebuilds `LocalDeliveryMarketplace_Team_28`, so don't run it while someone needs that database's contents.
- It writes `Team_28_results.txt` next to `Team_28.sql`.
- The guide says `grader.py`, `public_tests.sql` and the `.sql` file should be in one folder. Running it from this repo's layout (`python tests/grader.py Team_28.sql --server "(localdb)\MSSQLLocalDB"`) hasn't been tried yet.

**Ad-hoc checks:** SQL Server LocalDB is installed: `sqlcmd -S "(localdb)\MSSQLLocalDB"`. The script drops and recreates `LocalDeliveryMarketplace_Team_28`. To test without clobbering someone's working database:
1. Copy the script and replace the database name with a throwaway one, e.g. `sed 's/LocalDeliveryMarketplace_Team_28/Test_Team_28/g'`.
2. Append test statements (`EXEC dbo.createAllTables;`, sample inserts, ...) and finish with `USE master; DROP DATABASE Test_Team_28;`.
3. Run `sqlcmd -S "(localdb)\MSSQLLocalDB" -i <file>`. From Git Bash, pass a Windows path (`cygpath -w`).

## Open questions (ask on CMS)

- Appendix A lists no `CHECK (... IN (...))` constraints for status/type columns, although Section 1 says they must hold only the Section 2.3 values. They aren't added for now.
- The work split gives **Detect_Voucher_Abuse** to Student 1, but Section 4 never specifies it.
- **Recommended_Products**: the revised description lists it as a Hard item for Student 5, but it's still in Student 2's list and still missing from the official list of 8 hard requirements. Who owns it?
