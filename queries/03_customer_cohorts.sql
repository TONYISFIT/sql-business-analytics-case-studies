-- ============================================================================
-- 03 — Customer cohort analysis
-- ----------------------------------------------------------------------------
-- Business question: Do newer customer cohorts stay active longer than older
-- ones, or does engagement decay the same way for every cohort?
-- Approach: assign each customer to a signup-month cohort, then count distinct
-- active customers per (cohort, months-since-signup) cell. Reading across a
-- row shows how a cohort's activity decays over time.
-- Techniques: CTEs, date arithmetic, GROUP BY on two dimensions.
-- ============================================================================

WITH cohorts AS (
    SELECT
        customer_id,
        strftime('%Y-%m', signup_date) AS cohort_month
    FROM customers
),
activity AS (
    SELECT DISTINCT
        ch.cohort_month,
        (
            CAST(strftime('%Y', o.order_date) AS INTEGER) * 12
            + CAST(strftime('%m', o.order_date) AS INTEGER)
        )
        - (
            CAST(strftime('%Y', c.signup_date) AS INTEGER) * 12
            + CAST(strftime('%m', c.signup_date) AS INTEGER)
        ) AS period_index,
        o.customer_id
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN cohorts ch   ON ch.customer_id = c.customer_id
    WHERE o.status = 'delivered'
)
SELECT
    cohort_month,
    period_index AS months_since_signup,
    COUNT(DISTINCT customer_id) AS active_customers
FROM activity
WHERE period_index >= 0
GROUP BY 1, 2
ORDER BY 1, 2;
