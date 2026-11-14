"""
Databases I, Winter 2026, Milestone 2: PUBLIC TEST GRADER

Runs your Team_XX.sql file on a fresh database, then runs the public tests and
prints which tests passed and which failed.

Usage (in a terminal, in the folder that has this file and public_tests.sql):

    python grader.py Team_10.sql

Options:
    --server NAME      SQL Server to use. Default: tries localhost, localhost\\SQLEXPRESS
                       and (localdb)\\MSSQLLocalDB in that order.
    --user U --password P
                       SQL Server login. Default: your Windows login.
    --keep             Do not drop your database before running your file.

Needs: Python 3.8+, the pyodbc package (pip install pyodbc) and an ODBC driver for
SQL Server (installed with SQL Server; otherwise install "ODBC Driver 18 for SQL Server").

WARNING: by default the grader DROPS the database LocalDeliveryMarketplace_Team_XX named
in your file and rebuilds it from your file, exactly like a fresh server.
"""
import argparse
import os
import re
import sys

try:
    import pyodbc
except ImportError:
    sys.exit("pyodbc is not installed. Run:  pip install pyodbc   and try again.")

HERE = os.path.dirname(os.path.abspath(__file__))
GO_LINE = re.compile(r"^[ \t]*GO[ \t]*(?:--[^\r\n]*)?\r?$", re.IGNORECASE | re.MULTILINE)


def read_sql(path):
    raw = open(path, "rb").read()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16").replace("\r\n", "\n")
    try:
        return raw.decode("utf-8-sig").replace("\r\n", "\n")
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace")


def batches(text):
    """Split a script on GO lines. Returns (first line number, batch text) pairs."""
    out, start, pos = [], 1, 0
    for m in GO_LINE.finditer(text):
        chunk = text[pos:m.start()]
        if chunk.strip():
            out.append((start, chunk))
        start = text.count("\n", 0, m.end()) + 2
        pos = m.end()
    if text[pos:].strip():
        out.append((start, text[pos:]))
    return out


def pick_driver():
    names = pyodbc.drivers()
    for d in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server",
              "ODBC Driver 13 for SQL Server", "SQL Server Native Client 11.0", "SQL Server"):
        if d in names:
            return d
    sys.exit("No ODBC driver for SQL Server was found. Install 'ODBC Driver 18 for SQL Server' "
             "from Microsoft and try again.")


def connect(args, driver, server, database="master"):
    parts = [f"DRIVER={{{driver}}}", f"SERVER={server}", f"DATABASE={database}",
             "Encrypt=no", "TrustServerCertificate=yes"]
    if args.user:
        parts += [f"UID={args.user}", f"PWD={args.password or ''}"]
    else:
        parts.append("Trusted_Connection=yes")
    return pyodbc.connect(";".join(parts) + ";", autocommit=True, timeout=10)


def run_batch(conn, sql):
    """Runs one batch, reads every result. Returns (error message or None, printed messages)."""
    cur = conn.cursor()
    msgs = []
    try:
        cur.execute(sql)
        while True:
            msgs += [m[1] for m in (getattr(cur, "messages", None) or [])]
            if cur.description:
                cur.fetchall()
            if not cur.nextset():
                break
        return None, msgs
    except pyodbc.Error as e:
        text = str(e.args[1] if len(e.args) > 1 else e)
        text = re.sub(r"\[[^\]]*\]", "", text).replace("(SQLExecDirectW)", "").strip()
        return text, msgs
    finally:
        cur.close()


def clean(msg):
    return re.sub(r"\s*\(\d+\)\s*", " ", msg).strip()


def main():
    ap = argparse.ArgumentParser(description="Milestone 2 public test grader")
    ap.add_argument("team_file", help="your Team_XX.sql file")
    ap.add_argument("--server")
    ap.add_argument("--user")
    ap.add_argument("--password")
    ap.add_argument("--tests", default=os.path.join(HERE, "public_tests.sql"))
    ap.add_argument("--keep", action="store_true")
    args = ap.parse_args()

    if not os.path.isfile(args.team_file):
        sys.exit(f"File not found: {args.team_file}")
    if not os.path.isfile(args.tests):
        sys.exit(f"public_tests.sql not found at {args.tests}. Put it next to grader.py.")

    team_sql = read_sql(args.team_file)
    names = re.findall(r"CREATE\s+DATABASE\s+\[?(LocalDeliveryMarketplace_Team_\w+)\]?", team_sql, re.IGNORECASE)
    if not names:
        sys.exit("Your file must contain CREATE DATABASE LocalDeliveryMarketplace_Team_<number>.")
    db = next((n for n in names if not n.upper().endswith("_XX")), names[0])
    if db.upper().endswith("_XX"):
        sys.exit("Replace XX with your team number in your file (for example LocalDeliveryMarketplace_Team_10).")

    # 1) connect
    driver = pick_driver()
    servers = [args.server] if args.server else ["localhost", r"localhost\SQLEXPRESS", r"(localdb)\MSSQLLocalDB"]
    conn, server, last_err = None, None, None
    for s in servers:
        try:
            conn, server = connect(args, driver, s), s
            break
        except pyodbc.Error as e:
            last_err = e
    if conn is None:
        sys.exit(f"Could not connect to SQL Server ({', '.join(servers)}).\n"
                 f"Use --server with the server name you use in Visual Studio.\nDetails: {last_err}")
    version = conn.cursor().execute("SELECT SERVERPROPERTY('ProductVersion')").fetchone()[0]
    print(f"Connected to {server} (SQL Server {version}) with {driver}.")

    # 2) fresh database
    if not args.keep:
        exists = conn.cursor().execute("SELECT DB_ID(?)", db).fetchone()[0]
        if exists:
            print(f"Dropping {db} so your file runs on a fresh database (use --keep to skip).")
            err, _ = run_batch(conn, f"ALTER DATABASE [{db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [{db}];")
            if err:
                sys.exit(f"Could not drop {db}: {err}\nClose other connections to it (Visual Studio) and try again.")

    # 3) run the team file
    print(f"Running {os.path.basename(args.team_file)} ...")
    errors = []
    for line, sql in batches(team_sql):
        err, _ = run_batch(conn, sql)
        if err:
            errors.append((line, clean(err)))
    if errors:
        print(f"\nYour file raised {len(errors)} error(s). It must run without errors:")
        for line, err in errors[:15]:
            print(f"  batch starting at line {line}: {err}")
        if len(errors) > 15:
            print(f"  ... and {len(errors) - 15} more")
    else:
        print("Your file ran without errors.")
    conn.close()

    exists_conn = connect(args, driver, server)
    if not exists_conn.cursor().execute("SELECT DB_ID(?)", db).fetchone()[0]:
        sys.exit(f"\nThe database {db} was not created, so no test can run.")
    exists_conn.close()

    # 4) run the public tests in a new session on the team database
    print("Running the public tests (about one minute) ...")
    tests_sql = read_sql(args.tests)
    tests_sql = re.sub(r"USE\s+LocalDeliveryMarketplace_Team_\w+\s*;", f"USE [{db}];", tests_sql, count=1)
    tconn = connect(args, driver, server, db)
    notes, harness_errors = [], []
    for line, sql in batches(tests_sql):
        err, msgs = run_batch(tconn, sql)
        notes += [clean(re.sub(r"\[[^\]]*\]", "", x)) for x in msgs if "***" in x or "createAllTables first" in x]
        if err:
            harness_errors.append((line, clean(err)))
    for n in notes:
        print("  " + n)
    try:
        rows = tconn.cursor().execute(
            "SELECT test_id, kind, description, "
            "CASE WHEN finished = 1 AND fail_count = 0 THEN 'PASS' ELSE 'FAIL' END, "
            "CASE WHEN finished = 0 THEN N'Test stopped early. ' + details ELSE details END "
            "FROM #TestResults ORDER BY seq").fetchall()
    except pyodbc.Error:
        print("\nThe tests could not run.")
        for line, err in harness_errors[:5]:
            print(f"  line {line}: {err}")
        sys.exit(1)
    tconn.close()

    # 5) report: short on screen, full details in the results file
    SEED = "Could not reload the seed data"
    seed_errors = set()
    width = max(len(r[0]) for r in rows)
    screen, full = [], []
    for test_id, kind, desc, result, details in rows:
        head = f"{test_id.ljust(width)}  {result}  {desc}"
        screen.append(head)
        full.append(head)
        if result == "FAIL":
            parts = [x.strip() for x in (details or "").split(" || ") if x.strip()]
            for x in parts:
                if x.startswith(SEED):
                    seed_errors.add(x)
            shown = [x for x in parts if not x.startswith(SEED)] or parts
            for x in shown[:2]:
                screen.append(" " * (width + 8) + "- " + (x if len(x) <= 160 else x[:157] + "..."))
            if len(shown) > 2:
                screen.append(" " * (width + 8) + f"- ... {len(shown) - 2} more problem(s), see the results file")
            for x in parts:
                full.append(" " * (width + 8) + "- " + x)
    passed = sum(1 for r in rows if r[3] == "PASS")
    top = ["", "=" * 80, f"Results for {db}", "=" * 80]
    if seed_errors:
        top += ["FIX THIS FIRST: the seed data does not fit your tables, so most tests fail:"]
        top += ["  " + x for x in sorted(seed_errors)] + [""]
    bottom = ["", "=" * 80, f"PASSED {passed} of {len(rows)} public tests.",
              "Passing every public test does not guarantee full marks: the TAs also run private tests."]
    print("\n".join(top + screen + bottom))
    result_file = os.path.splitext(os.path.abspath(args.team_file))[0] + "_results.txt"
    with open(result_file, "w", encoding="utf-8") as f:
        f.write("\n".join(top[1:] + full + bottom) + "\n")
    print(f"Full details of every failed test: {result_file}")


if __name__ == "__main__":
    main()
