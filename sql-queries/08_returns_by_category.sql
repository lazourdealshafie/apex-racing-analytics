-- =====================================================================
-- Q8: Which product categories get returned most, and why?
-- =====================================================================
-- Business question:
--   Merchandising wants to know where to focus quality and sizing
--   fixes: which categories have the highest return rate, and for
--   each category, what's the single most common reason customers
--   send items back?
--
-- Approach:
--   Part A: for every delivered order line, LEFT JOIN to returns on
--   the same (order_id, product_id) pair. A line with no matching
--   return keeps a NULL on the right side, so COUNT(rl.order_id)
--   only counts lines that were actually returned -- COUNT ignores
--   NULLs, which is what makes this pattern work.
--   Part B: count return reasons per category, then use RANK() to
--   find the single most common reason in each category, filtering
--   to rank = 1 in an outer query (you can't put a window function
--   directly in a WHERE clause, so it has to be wrapped in a CTE).
-- =====================================================================

SET search_path TO apex;

-- Part A: return rate by category
WITH delivered_lines AS (
    SELECT
        i.order_id,
        i.product_id,
        p.category
    FROM order_items i
    JOIN orders o   ON o.order_id = i.order_id
    JOIN products p ON p.product_id = i.product_id
    WHERE o.status = 'delivered'
),
returned_lines AS (
    SELECT DISTINCT order_id, product_id
    FROM returns
)
SELECT
    d.category,
    COUNT(*)                                                  AS lines_delivered,
    COUNT(rl.order_id)                                        AS lines_returned,
    ROUND(100.0 * COUNT(rl.order_id) / COUNT(*), 1)           AS return_rate_pct
FROM delivered_lines d
LEFT JOIN returned_lines rl
    ON rl.order_id = d.order_id AND rl.product_id = d.product_id
GROUP BY d.category
ORDER BY return_rate_pct DESC;

-- Part B: the single most common return reason per category
WITH reason_counts AS (
    SELECT
        p.category,
        r.reason,
        COUNT(*) AS times_cited
    FROM returns r
    JOIN products p ON p.product_id = r.product_id
    GROUP BY p.category, r.reason
),
ranked_reasons AS (
    SELECT
        category,
        reason,
        times_cited,
        RANK() OVER (PARTITION BY category ORDER BY times_cited DESC) AS reason_rank,
        ROUND(100.0 * times_cited / SUM(times_cited) OVER (PARTITION BY category), 1) AS pct_of_category_returns
    FROM reason_counts
)
SELECT
    category,
    reason        AS top_return_reason,
    times_cited,
    pct_of_category_returns
FROM ranked_reasons
WHERE reason_rank = 1
ORDER BY category;
