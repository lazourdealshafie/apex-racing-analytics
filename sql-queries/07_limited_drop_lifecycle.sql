-- =====================================================================
-- Q7: How fast do limited drops sell, and how does that compare to
--     the core/heritage lines?
-- =====================================================================
-- Business question:
--   Limited circuit-themed drops (e.g. "Monaco 2025 Limited Drop") are
--   meant to sell hard and fast around a race weekend. Merchandising
--   wants proof: do they actually front-load their sales into the
--   first few weeks, and do they outsell the regular lineup per day
--   while they're hot?
--
-- Approach:
--   Part A looks only at limited-drop products and splits their
--   revenue into "first 21 days after launch" vs "later," to test
--   whether the drop really does sell out its momentum early.
--   Part B compares limited drops to core/heritage products on a
--   level playing field: average revenue per day, counting only each
--   product's own first 21 days on sale, so a long-running core item
--   isn't penalized just for having more calendar time behind it.
-- =====================================================================

SET search_path TO apex;

-- Part A: limited-drop revenue -- first 21 days vs. later
WITH limited_lines AS (
    SELECT
        i.product_id,
        o.order_date,
        DATE(o.order_date) - p.launch_date                          AS days_since_launch,
        i.quantity,
        i.quantity * i.unit_price * (1 - i.discount_pct / 100.0)     AS net_revenue
    FROM order_items i
    JOIN orders o    ON o.order_id = i.order_id
    JOIN products p  ON p.product_id = i.product_id
    WHERE p.collection LIKE '%Limited Drop'
      AND o.status != 'cancelled'
),
labeled AS (
    SELECT
        *,
        CASE WHEN days_since_launch <= 21 THEN 'first 21 days' ELSE 'later' END AS sale_window,
        CASE WHEN days_since_launch <= 21 THEN 1 ELSE 2 END                     AS sale_window_sort
    FROM limited_lines
)
SELECT
    sale_window,
    SUM(quantity)                                    AS units_sold,
    ROUND(SUM(net_revenue))                          AS net_revenue,
    ROUND(100.0 * SUM(net_revenue) / SUM(SUM(net_revenue)) OVER (), 1) AS pct_of_drop_revenue
FROM labeled
GROUP BY sale_window, sale_window_sort
ORDER BY sale_window_sort;

-- Part B: average daily revenue in each product's own first 21 days --
-- limited drops vs. core/heritage collections, same-length window
-- for both, so the comparison is fair
WITH first_21_days AS (
    SELECT
        p.product_id,
        CASE WHEN p.collection LIKE '%Limited Drop' THEN 'limited drop' ELSE 'core / heritage' END AS product_type,
        i.quantity * i.unit_price * (1 - i.discount_pct / 100.0) AS net_revenue
    FROM order_items i
    JOIN orders o   ON o.order_id = i.order_id
    JOIN products p ON p.product_id = i.product_id
    WHERE o.status != 'cancelled'
      AND DATE(o.order_date) - p.launch_date BETWEEN 0 AND 21
)
SELECT
    product_type,
    COUNT(DISTINCT product_id)                        AS products_included,
    ROUND(SUM(net_revenue))                            AS total_revenue_first_21d,
    ROUND(SUM(net_revenue) / 21.0 / COUNT(DISTINCT product_id), 2) AS avg_revenue_per_product_per_day
FROM first_21_days
GROUP BY product_type
ORDER BY product_type;
