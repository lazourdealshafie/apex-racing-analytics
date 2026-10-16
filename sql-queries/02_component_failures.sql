-- =====================================================================
-- Q2: Which components fail most often, and what do they cost?
-- =====================================================================
-- Business question:
--   The engineering team wants to know where reliability spend should
--   go. Which component categories fail most often, how much does each
--   failure cost, and does that change in wet conditions?
--
-- Approach:
--   1. maintenance_logs.event_type = 'failure' marks an unplanned
--      breakdown (as opposed to a routine 'inspection' or a planned
--      'replacement'), so we filter to that.
--   2. Join to components to get the category, and to races to check
--      the weather that day (a maintenance log's race_id is NULL for
--      off-season work, so a LEFT JOIN keeps those rows and just
--      leaves weather blank for them).
--   3. Aggregate failure count and total/average cost per category,
--      and separately per category x weather, so both angles are
--      available from one run.
-- =====================================================================

SET search_path TO apex;

-- Part A: failures and cost by component category
WITH failures AS (
    SELECT
        m.log_id,
        m.cost,
        c.category,
        r.weather
    FROM maintenance_logs m
    JOIN components c   ON c.component_id = m.component_id
    LEFT JOIN races r   ON r.race_id = m.race_id   -- off-season work has no race
    WHERE m.event_type = 'failure'
)
SELECT
    category,
    COUNT(*)                                   AS failure_count,
    ROUND(SUM(cost))                           AS total_cost,
    ROUND(AVG(cost))                           AS avg_cost_per_failure,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all_failures
FROM failures
GROUP BY category
ORDER BY total_cost DESC;

-- Part B: failure rate by category, split wet vs. dry/mixed races
-- (rate = failures in that category / total race entries run in that
--  weather, so wet and dry are comparable even though there are far
--  fewer wet races)
WITH entries_by_weather AS (
    -- group the same way on both sides (wet vs. dry_or_mixed) so the
    -- join below is a plain equality, not a special case
    SELECT
        CASE WHEN r.weather = 'wet' THEN 'wet' ELSE 'dry_or_mixed' END AS weather_group,
        COUNT(*) AS total_entries
    FROM race_entries e
    JOIN races r ON r.race_id = e.race_id
    GROUP BY weather_group
),
failures_by_weather AS (
    SELECT
        c.category,
        CASE WHEN r.weather = 'wet' THEN 'wet' ELSE 'dry_or_mixed' END AS weather_group,
        COUNT(*) AS failure_count
    FROM maintenance_logs m
    JOIN components c ON c.component_id = m.component_id
    JOIN races r      ON r.race_id = m.race_id     -- only race-day failures here
    WHERE m.event_type = 'failure'
    GROUP BY c.category, weather_group
)
SELECT
    f.category,
    f.weather_group,
    f.failure_count,
    ROUND(100.0 * f.failure_count / ew.total_entries, 1) AS failures_per_100_entries
FROM failures_by_weather f
JOIN entries_by_weather ew ON ew.weather_group = f.weather_group
ORDER BY f.category, f.weather_group;