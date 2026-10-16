-- =====================================================================
-- Q6: Do merch sales spike after a race win?
-- =====================================================================
-- Business question:
--   The marketing team wants to know whether it's worth timing email
--   blasts and promo pushes around race results. Do orders actually
--   jump after a win, and if so, for how long does the lift last?
--
-- Approach:
--   Part A: for every calendar day with at least one order, find the
--   most recent race win on or before that day using a LATERAL join
--   (a subquery that runs once per row of the left-hand table, so it
--   can find "the nearest matching row" without a big multi-way join).
--   Bucket each day by how many days it's been since that win, then
--   compare average daily orders and revenue across buckets.
--
--   Part B: same idea, but zoomed in day-by-day for the two days
--   before and five days after each win, to show the actual shape of
--   the spike and how fast it fades.
-- =====================================================================

SET search_path TO apex;

-- Part A: daily order volume, bucketed by days since the last win
WITH win_dates AS (
    SELECT DISTINCT r.race_date
    FROM race_entries e
    JOIN races r ON r.race_id = e.race_id
    WHERE e.finish_position = 1
),
daily_orders AS (
    SELECT
        DATE(order_date)                    AS order_day,
        COUNT(*)                            AS orders_that_day
    FROM orders
    GROUP BY DATE(order_date)
),
daily_with_win_gap AS (
    SELECT
        d.order_day,
        d.orders_that_day,
        d.order_day - w.race_date           AS days_since_win,  -- NULL if no win happened yet
        CASE
            WHEN w.race_date IS NULL                        THEN 'before any win'
            WHEN d.order_day - w.race_date BETWEEN 0 AND 2  THEN '0-2 days after a win'
            WHEN d.order_day - w.race_date BETWEEN 3 AND 7  THEN '3-7 days after a win'
            ELSE '8+ days after a win'
        END                                  AS window_bucket,
        -- Postgres won't let an ORDER BY expression reference a SELECT
        -- alias inside a CASE (only a bare alias by itself is allowed),
        -- so the sort order is computed here as its own plain column
        -- instead of rebuilding the CASE on window_bucket down in ORDER BY.
        CASE
            WHEN w.race_date IS NULL                        THEN 4
            WHEN d.order_day - w.race_date BETWEEN 0 AND 2  THEN 1
            WHEN d.order_day - w.race_date BETWEEN 3 AND 7  THEN 2
            ELSE 3
        END                                  AS bucket_sort_order
    FROM daily_orders d
    LEFT JOIN LATERAL (
        SELECT race_date
        FROM win_dates
        WHERE race_date <= d.order_day
        ORDER BY race_date DESC
        LIMIT 1
    ) w ON TRUE
)
SELECT
    window_bucket,
    COUNT(*)                                 AS days_in_bucket,
    ROUND(AVG(orders_that_day), 1)           AS avg_orders_per_day
FROM daily_with_win_gap
GROUP BY window_bucket, bucket_sort_order
ORDER BY bucket_sort_order;

-- Part B: day-by-day shape of the spike around each win
-- (-2 to +5 days, averaged across every win in the dataset)
WITH win_dates AS (
    SELECT DISTINCT r.race_date
    FROM race_entries e
    JOIN races r ON r.race_id = e.race_id
    WHERE e.finish_position = 1
),
daily_orders AS (
    SELECT DATE(order_date) AS order_day, COUNT(*) AS orders_that_day
    FROM orders
    GROUP BY DATE(order_date)
)
SELECT
    (d.order_day - w.race_date)              AS days_from_win,
    COUNT(*)                                 AS observations,
    ROUND(AVG(d.orders_that_day), 1)         AS avg_orders_per_day
FROM win_dates w
JOIN daily_orders d
    ON d.order_day BETWEEN w.race_date - 2 AND w.race_date + 5
GROUP BY days_from_win
ORDER BY days_from_win;
