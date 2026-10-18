-- ============================================================================
-- 02 — Top products by revenue
-- ----------------------------------------------------------------------------
-- Business question: Which products drive revenue, and how concentrated is
-- revenue across the catalogue?
-- Approach: roll order-line revenue up to product level, RANK() products by
-- revenue, and compute each product's share of total revenue with a windowed
-- SUM() so concentration is visible in one pass.
-- Techniques: CTE, multi-table JOIN, GROUP BY, RANK(), windowed SUM().
-- ============================================================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity)                  AS units_sold,
        SUM(oi.quantity * oi.unit_price)   AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN orders o   ON o.order_id   = oi.order_id
    WHERE o.status = 'delivered'
    GROUP BY 1, 2, 3
)
SELECT
    product_name,
    category,
    units_sold,
    ROUND(revenue, 2)                                        AS revenue,
    RANK() OVER (ORDER BY revenue DESC)                      AS revenue_rank,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)         AS pct_of_total_revenue
FROM product_revenue
ORDER BY revenue_rank
LIMIT 10;
