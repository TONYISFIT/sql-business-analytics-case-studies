"""Pytest suite: every case-study query must run cleanly and return data."""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from verify import EXPECTED_COLUMNS, QUERIES, build_db, run_query


@pytest.fixture(scope="module")
def con():
    connection = build_db()
    yield connection
    connection.close()


@pytest.mark.parametrize("name", sorted(EXPECTED_COLUMNS))
def test_query_returns_rows(con, name):
    cols, rows = run_query(con, QUERIES / name)
    assert rows, f"{name} returned no rows"


@pytest.mark.parametrize("name", sorted(EXPECTED_COLUMNS))
def test_query_has_expected_columns(con, name):
    cols, _ = run_query(con, QUERIES / name)
    missing = EXPECTED_COLUMNS[name] - set(cols)
    assert not missing, f"{name} missing columns: {missing}"


def test_seed_data_present(con):
    customers = con.execute("SELECT COUNT(*) FROM customers").fetchone()[0]
    orders = con.execute("SELECT COUNT(*) FROM orders").fetchone()[0]
    assert customers >= 100, "seed should contain a few hundred customers"
    assert orders >= 500, "seed should contain a few hundred orders"


def test_retention_rate_sane(con):
    cols, rows = run_query(con, QUERIES / "04_retention_analysis.sql")
    rate = rows[0][cols.index("repeat_rate_pct")]
    assert 0 <= rate <= 100, f"repeat rate out of range: {rate}"
