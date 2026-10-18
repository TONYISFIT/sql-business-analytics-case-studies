-- ============================================================================
-- 04 — Retention: repeat purchase rate
-- ----------------------------------------------------------------------------
-- Business question: What share of customers ever come back for a second
-- purchase, and how quickly does that second purchase happen?
-- Approach: find each customer's first delivered order date, then their first
-- delivered order strictly after that date (self-join anti-pattern avoided via
-- a second aggregation). LEFT JOIN keeps one-time buyers in the denominator.
-- Techniques: CTEs, self-join on aggregated dates, julianday() date math,
-- conditional aggregation.
-- ============================================================================

WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'delivered'
    GROUP BY 1
),
second_orders AS (
    SELECT o.customer_id, MIN(o.order_date) AS second_order_date
    FROM orders o
    JOIN first_orders f ON f.customer_id = o.customer_id
    WHERE o.status = 'delivered'
      AND o.order_date > f.first_order_date
    GROUP BY 1
)
SELECT
    COUNT(*)                                                        AS total_customers,
    COUNT(s.second_order_date)                                      AS repeat_customers,
    COUNT(*) - COUNT(s.second_order_date)                           AS one_time_customers,
    ROUND(100.0 * COUNT(s.second_order_date) / COUNT(*), 2)          AS repeat_rate_pct,
    ROUND(AVG(julianday(s.second_order_date)
              - julianday(f.first_order_date)), 1)                  AS avg_days_to_second_order
FROM first_orders f
LEFT JOIN second_orders s ON s.customer_id = f.customer_id;
