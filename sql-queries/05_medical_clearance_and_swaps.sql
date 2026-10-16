-- =====================================================================
-- Q5: How often does a failed medical check bench a driver, and how
--     does the reserve perform when subbed in?
-- =====================================================================
-- Business question:
--   Every driver gets a pre-race medical check (fitness, hydration,
--   sleep) that must pass to be "cleared" to race. When a primary
--   driver isn't cleared, the reserve steps in. Leadership wants to
--   know: how often does this actually happen, and does the team lose
--   much performance when it does?
--
-- Approach:
--   Part A joins each primary driver's pre-race medical check to
--   whether they actually appear in race_entries that race (a LEFT
--   JOIN, so a driver who failed clearance and sat out still shows up
--   with no matching entry). That flags every swap.
--   Part B compares points, finish position, and DNF rate for races
--   the reserve actually drove vs. races either primary driver drove,
--   as a simple aggregate comparison.
-- =====================================================================

SET search_path TO apex;

-- Part A: clearance outcomes for the two primary drivers
WITH primary_checks AS (
    SELECT
        m.race_id,
        m.personnel_id                                       AS driver_id,
        p.first_name || ' ' || p.last_name                    AS driver_name,
        m.cleared
    FROM medical_checks m
    JOIN personnel p ON p.personnel_id = m.personnel_id
    WHERE p.role = 'driver'          -- primary drivers only, not the reserve
)
SELECT
    pc.driver_name,
    COUNT(*)                                                  AS checks_taken,
    SUM(CASE WHEN pc.cleared THEN 1 ELSE 0 END)                AS times_cleared,
    SUM(CASE WHEN NOT pc.cleared THEN 1 ELSE 0 END)             AS times_not_cleared,
    SUM(CASE WHEN NOT pc.cleared AND e.driver_id IS NULL THEN 1 ELSE 0 END)
                                                               AS times_swapped_out
FROM primary_checks pc
LEFT JOIN race_entries e
    ON e.race_id = pc.race_id AND e.driver_id = pc.driver_id
GROUP BY pc.driver_name
ORDER BY pc.driver_name;

-- Part B: reserve driver performance vs. primary drivers, in races
-- the reserve actually entered (so it's the same set of races on
-- both sides of the comparison, not the reserve's easy races vs.
-- the primaries' full season)
WITH reserve_races AS (
    SELECT DISTINCT race_id
    FROM race_entries e
    JOIN personnel p ON p.personnel_id = e.driver_id
    WHERE p.role = 'reserve_driver'
)
SELECT
    CASE WHEN p.role = 'reserve_driver' THEN 'reserve' ELSE 'primary' END AS driver_type,
    COUNT(*)                                                  AS entries,
    ROUND(AVG(e.points), 2)                                   AS avg_points,
    ROUND(AVG(CASE WHEN e.dnf = FALSE THEN e.finish_position END), 1) AS avg_finish_pos,
    ROUND(100.0 * SUM(CASE WHEN e.dnf THEN 1 ELSE 0 END) / COUNT(*), 1) AS dnf_rate_pct
FROM race_entries e
JOIN personnel p ON p.personnel_id = e.driver_id
WHERE e.race_id IN (SELECT race_id FROM reserve_races)
GROUP BY driver_type
ORDER BY driver_type;
