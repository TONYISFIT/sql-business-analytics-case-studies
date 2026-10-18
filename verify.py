#!/usr/bin/env python3
"""Verify every query in queries/ against the synthetic schema+seed.

Loads schema.sql + seed.sql into an in-memory SQLite database, runs each
query file, asserts it returns rows and its expected key columns, and writes
sample outputs (first 10 rows) to results/<name>.csv plus results/summary.md.
"""
import csv
import sqlite3
from pathlib import Path

BASE = Path(__file__).resolve().parent
QUERIES = BASE / "queries"
RESULTS = BASE / "results"

# query file -> key columns that must be present in the result
EXPECTED_COLUMNS = {
    "01_monthly_revenue_trend.sql": {"month", "revenue", "mom_growth_pct"},
    "02_top_products_by_revenue.sql": {"product_name", "revenue", "revenue_rank"},
    "03_customer_cohorts.sql": {"cohort_month", "months_since_signup", "active_customers"},
    "04_retention_analysis.sql": {"total_customers", "repeat_rate_pct"},
    "05_rfm_segmentation.sql": {"customer_id", "segment", "monetary"},
}


def build_db() -> sqlite3.Connection:
    con = sqlite3.connect(":memory:")
    con.executescript((BASE / "schema.sql").read_text())
    con.executescript((BASE / "seed.sql").read_text())
    return con


def run_query(con: sqlite3.Connection, path: Path):
    sql = path.read_text()
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    return cols, rows


def main() -> None:
    RESULTS.mkdir(exist_ok=True)
    con = build_db()
    summary = ["# Verification summary", "",
               "All queries executed against the synthetic seed data in SQLite.",
               ""]
    for name in sorted(EXPECTED_COLUMNS):
        cols, rows = run_query(con, QUERIES / name)
        assert rows, f"{name} returned no rows"
        missing = EXPECTED_COLUMNS[name] - set(cols)
        assert not missing, f"{name} missing columns: {missing}"
        # write sample csv (header + first 10 rows)
        with open(RESULTS / f"{Path(name).stem}.csv", "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(cols)
            w.writerows(rows[:10])
        summary.append(f"## {name}")
        summary.append(f"- Rows returned: **{len(rows)}**")
        summary.append(f"- Columns: {', '.join(cols)}")
        summary.append("")
        print(f"OK  {name}: {len(rows)} rows, columns verified")
    (RESULTS / "summary.md").write_text("\n".join(summary))
    print(f"\nAll {len(EXPECTED_COLUMNS)} queries verified. Samples in results/")


if __name__ == "__main__":
    main()
