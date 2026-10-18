-- ============================================================================
-- 05 — RFM customer segmentation
-- ----------------------------------------------------------------------------
-- Business question: Which customers are most valuable right now, and which
-- valuable customers are slipping away (at risk)?
-- Approach: compute Recency (days since last order), Frequency (order count)
-- and Monetary (lifetime spend) per customer, score each dimension into
-- quintiles with NTILE(5), then map score combinations to business segments.
-- Reference date 2025-12-31 matches the end of the synthetic data window.
-- Techniques: CTEs, NTILE() window function, CASE-based segmentation.
-- ============================================================================

WITH rfm AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        CAST(julianday('2025-12-31') - julianday(MAX(o.order_date)) AS INTEGER) AS recency_days,
        COUNT(DISTINCT o.order_id)              AS frequency,
        SUM(oi.quantity * oi.unit_price)        AS monetary
    FROM customers c
    JOIN orders o      ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id  = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY 1, 2
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM rfm
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
        WHEN r_score <= 2                   THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM scored
ORDER BY monetary DESC
LIMIT 25;
