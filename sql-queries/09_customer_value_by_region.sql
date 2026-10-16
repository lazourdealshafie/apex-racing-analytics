-- =====================================================================
-- Q9: Which regions generate the most customer value, and who are
--     the highest-value customers?
-- =====================================================================
-- Business question:
--   Leadership wants a region-level view of the merch business for
--   planning ad spend, plus a shortlist of the highest-value
--   customers worth a personal outreach (a VIP email, an invite to a
--   trackside meet-and-greet, etc).
--
-- Approach:
--   Part A aggregates net revenue, order count, and customer count by
--   region, then uses HAVING to keep only regions whose average order
--   value beats the company-wide average -- a filter on an aggregate
--   result, which is exactly what HAVING is for (WHERE can't filter
--   on an aggregate like AVG()).
--   Part B ranks individual customers by lifetime net revenue with
--   RANK() and keeps the top 10, giving a concrete VIP list.
-- =====================================================================

SET search_path TO apex;

-- Part A: region-level value, keeping only above-average regions
WITH order_value AS (
    SELECT
        o.order_id,
        c.region,
        c.customer_id,
        SUM(i.quantity * i.unit_price * (1 - i.discount_pct / 100.0)) AS order_net_revenue
    FROM orders o
    JOIN customers c    ON c.customer_id = o.customer_id
    JOIN order_items i  ON i.order_id = o.order_id
    WHERE o.status != 'cancelled'
    GROUP BY o.order_id, c.region, c.customer_id
),
company_avg AS (
    SELECT AVG(order_net_revenue) AS company_avg_order_value
    FROM order_value
)
SELECT
    ov.region,
    COUNT(DISTINCT ov.customer_id)                         AS customers,
    COUNT(*)                                               AS orders,
    ROUND(SUM(ov.order_net_revenue))                       AS total_net_revenue,
    ROUND(AVG(ov.order_net_revenue), 2)                    AS avg_order_value,
    ROUND(SUM(ov.order_net_revenue) / COUNT(DISTINCT ov.customer_id), 2) AS revenue_per_customer
FROM order_value ov
GROUP BY ov.region
HAVING AVG(ov.order_net_revenue) > (SELECT company_avg_order_value FROM company_avg)
ORDER BY avg_order_value DESC;

-- Part B: top 10 customers by lifetime net revenue
WITH customer_value AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name                    AS customer_name,
        c.region,
        COUNT(DISTINCT o.order_id)                             AS total_orders,
        SUM(i.quantity * i.unit_price * (1 - i.discount_pct / 100.0)) AS lifetime_net_revenue
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id AND o.status != 'cancelled'
    JOIN order_items i  ON i.order_id = o.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.region
)
SELECT
    RANK() OVER (ORDER BY lifetime_net_revenue DESC) AS value_rank,
    customer_name,
    region,
    total_orders,
    ROUND(lifetime_net_revenue, 2)                    AS lifetime_net_revenue
FROM customer_value
ORDER BY value_rank
LIMIT 10;
