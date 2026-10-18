-- ============================================================================
-- 01 — Monthly revenue trend
-- ----------------------------------------------------------------------------
-- Business question: How is revenue trending month over month, and where are
-- the inflection points (growth spikes / slowdowns)?
-- Approach: aggregate delivered-order revenue per calendar month, then use the
-- LAG() window function to compare each month against the previous one and
-- derive month-over-month growth %.
-- Techniques: CTE, JOIN, GROUP BY, aggregate functions, window function LAG().
-- ============================================================================

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        COUNT(DISTINCT o.order_id)       AS orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2)                                   AS revenue,
    orders,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)        AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    )                                                   AS mom_growth_pct
FROM monthly
ORDER BY month;
