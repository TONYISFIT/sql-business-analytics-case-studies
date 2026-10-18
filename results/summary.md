# Verification summary

All queries executed against the synthetic seed data in SQLite.

## 01_monthly_revenue_trend.sql
- Rows returned: **12**
- Columns: month, revenue, orders, prev_month_revenue, mom_growth_pct

## 02_top_products_by_revenue.sql
- Rows returned: **10**
- Columns: product_name, category, units_sold, revenue, revenue_rank, pct_of_total_revenue

## 03_customer_cohorts.sql
- Rows returned: **126**
- Columns: cohort_month, months_since_signup, active_customers

## 04_retention_analysis.sql
- Rows returned: **1**
- Columns: total_customers, repeat_customers, one_time_customers, repeat_rate_pct, avg_days_to_second_order

## 05_rfm_segmentation.sql
- Rows returned: **25**
- Columns: customer_id, customer_name, recency_days, frequency, monetary, r_score, f_score, m_score, segment
