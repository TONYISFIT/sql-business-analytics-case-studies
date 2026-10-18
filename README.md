# SQL Business Analytics Case Studies

Five end-to-end SQL case studies on a synthetic e-commerce dataset, covering the
analytical patterns that come up most in data analyst interviews and on the job:
trend analysis, ranking, cohorts, retention, and RFM segmentation.

> **All data is synthetic** — generated deterministically (`random.seed(42)`) for
> practice. No real customers, products, or transactions. Every result shown
> below was produced by actually running the queries (see `verify.py`).

## Dataset

| Table | Rows | Contents |
|---|---|---|
| `customers` | 300 | id, name, email, city, signup date (2024-06 → 2025-11) |
| `products` | 28 | id, name, category, unit price |
| `orders` | 1,200 | id, customer, order date (2025), status |
| `order_items` | 2,950 | order line: product, quantity, unit price |

Schema: [`schema.sql`](schema.sql) · Seed data: [`seed.sql`](seed.sql)

## Compatibility

Queries are written for **SQLite** (verified — run `python verify.py`) and use
standard SQL: CTEs, window functions (`LAG`, `RANK`, `NTILE`), and conditional
aggregation. They run unchanged on **PostgreSQL**, and on **MySQL 8+** with one
note: replace `strftime('%Y-%m', col)` with `DATE_FORMAT(col, '%Y-%m')` and
`julianday()` date math with `DATEDIFF()`.

## Case studies

### 1. Monthly revenue trend — [`queries/01_monthly_revenue_trend.sql`](queries/01_monthly_revenue_trend.sql)
**Business question:** How is revenue trending month over month, and where are
the inflection points?
**Approach:** Aggregate delivered-order revenue per month, then `LAG()` over the
ordered months to compute month-over-month growth %.
**Key SQL:**
```sql
ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
      / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS mom_growth_pct
```
**Sample result (real output):**

| month | revenue | orders | mom_growth_pct |
|---|---|---|---|
| 2025-01 | 62,011 | 10 | — |
| 2025-02 | 47,520 | 6 | -23.37 |
| 2025-03 | 75,998 | 12 | 59.93 |
| 2025-04 | 241,057 | 41 | 217.19 |
| 2025-05 | 344,200 | 48 | 42.79 |
| 2025-06 | 310,185 | 42 | -9.88 |

### 2. Top products by revenue — [`queries/02_top_products_by_revenue.sql`](queries/02_top_products_by_revenue.sql)
**Business question:** Which products drive revenue, and how concentrated is it?
**Approach:** Roll order lines up to product level, `RANK()` by revenue, and use
a windowed `SUM()` to show each product's share of total revenue in one pass.
**Sample result (real output):**

| product | category | revenue | rank | % of total |
|---|---|---|---|---|
| Air Fryer | Home | 1,116,297 | 1 | 14.40 |
| Smart Watch | Electronics | 775,806 | 2 | 10.00 |
| Mechanical Keyboard | Electronics | 689,303 | 3 | 8.89 |
| Wireless Headphones | Electronics | 497,301 | 4 | 6.41 |
| Coffee Maker | Home | 428,247 | 5 | 5.52 |

### 3. Customer cohort analysis — [`queries/03_customer_cohorts.sql`](queries/03_customer_cohorts.sql)
**Business question:** Do newer signup cohorts stay active longer than older ones?
**Approach:** Cohort = signup month; count distinct active customers per
(cohort, months-since-signup) cell so each row shows a cohort's decay curve.
**Sample result (real output, first rows):**

| cohort_month | months_since_signup | active_customers |
|---|---|---|
| 2024-07 | 9 | 2 |
| 2024-07 | 10 | 1 |
| 2024-07 | 16 | 2 |
| 2024-08 | 5 | 2 |

### 4. Retention: repeat purchase rate — [`queries/04_retention_analysis.sql`](queries/04_retention_analysis.sql)
**Business question:** What share of customers come back for a second purchase,
and how fast?
**Approach:** First-order date per customer, then first order strictly after it
(self-join on aggregated dates); `LEFT JOIN` keeps one-time buyers in the
denominator.
**Sample result (real output):**

| total_customers | repeat_customers | one_time | repeat_rate_pct | avg_days_to_2nd_order |
|---|---|---|---|---|
| 295 | 224 | 71 | 75.93 | 62.6 |

### 5. RFM segmentation — [`queries/05_rfm_segmentation.sql`](queries/05_rfm_segmentation.sql)
**Business question:** Who are the most valuable customers, and which valuable
ones are slipping away?
**Approach:** Recency / Frequency / Monetary per customer, quintile-scored with
`NTILE(5)`, mapped to segments (Champions, Loyal, Potential, At risk, Lost).
**Sample result (real output):**

| customer | recency_days | frequency | monetary | segment |
|---|---|---|---|---|
| Krishna Verma | 27 | 7 | 97,708 | Champions |
| Ira Menon | 10 | 6 | 95,109 | Champions |
| Shreya Patel | 58 | 5 | 81,857 | At risk |
| Nikhil Joshi | 7 | 9 | 79,419 | Champions |

## Run it

```bash
# verify every query against the seed data (SQLite, stdlib only)
python verify.py

# run the pytest suite
pip install -r requirements.txt
pytest -q
```

`verify.py` writes per-query samples to `results/` (first 10 rows as CSV) and a
`results/summary.md` with row counts.

CI (`.github/workflows/ci.yml`) runs `verify.py` + `pytest` on Python
3.10 / 3.11 / 3.12.

## Techniques demonstrated

Joins · CTEs · window functions (`LAG`, `RANK`, `NTILE`) · conditional
aggregation · date arithmetic · cohort/retention logic · RFM segmentation ·
deterministic synthetic data generation · automated SQL verification with pytest.
