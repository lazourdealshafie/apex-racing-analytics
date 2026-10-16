-- =====================================================================
-- Q1: Does a driver's fitness score affect lap pace and results?
-- =====================================================================
-- Business question:
--   The team's medical staff run a fitness/hydration/sleep check on
--   drivers before every race. Does a low score actually cost time on
--   track, or is it just a box-checking exercise?
--
-- Approach:
--   1. Pull "clean" laps only (no pit-in/out laps, dry races, past lap 2
--      so we skip the standing-start lap), because pit stops and rain
--      swing lap times far more than fitness ever would.
--   2. For each race entry, compare their average clean-lap time to
--      that race's average clean-lap time. This "delta" controls for
--      circuit length and conditions, so a slow street circuit doesn't
--      get compared against a fast power circuit.
--   3. Bucket entries by the driver's fitness score that day and look
--      at the average pace delta, average points, and average finish
--      per bucket.
-- =====================================================================

SET search_path TO apex;

WITH clean_laps AS (
    SELECT
        l.entry_id,
        l.lap_time_ms,
        e.race_id,
        e.driver_id
    FROM lap_times l
    JOIN race_entries e ON e.entry_id = l.entry_id
    JOIN races r        ON r.race_id  = e.race_id
    WHERE l.is_pit_lap = FALSE     -- drop in/out laps of a pit stop
      AND l.lap_number > 2         -- drop the standing-start lap
      AND r.weather = 'dry'        -- rain swamps every other effect
),
race_avg AS (
    SELECT
        race_id,
        AVG(lap_time_ms) AS race_avg_ms
    FROM clean_laps
    GROUP BY race_id
),
entry_pace AS (
    SELECT
        c.entry_id,
        c.driver_id,
        c.race_id,
        AVG(c.lap_time_ms) - MAX(race_avg_ms) AS pace_delta_ms,
        COUNT(*) AS clean_laps_used
    FROM clean_laps c
    JOIN race_avg ra ON ra.race_id = c.race_id
    GROUP BY c.entry_id, c.driver_id, c.race_id
)
SELECT
    CASE
        WHEN m.fitness_score >= 75 THEN '75+ (fit)'
        WHEN m.fitness_score >= 65 THEN '65-74 (borderline)'
        ELSE '<65 (poor)'
    END                                       AS fitness_band,
    COUNT(*)                                  AS race_entries,
    ROUND(AVG(ep.pace_delta_ms))              AS avg_pace_delta_ms,  -- vs race average; negative = faster
    ROUND(AVG(re.points), 2)                  AS avg_points,
    ROUND(AVG(CASE WHEN re.dnf = FALSE THEN re.finish_position END), 1) AS avg_finish_pos,
    ROUND(100.0 * SUM(CASE WHEN re.dnf THEN 1 ELSE 0 END) / COUNT(*), 1) AS dnf_rate_pct
FROM entry_pace ep
JOIN medical_checks m ON m.personnel_id = ep.driver_id AND m.race_id = ep.race_id
JOIN race_entries re  ON re.entry_id = ep.entry_id
GROUP BY fitness_band
ORDER BY fitness_band;

-- How to read avg_pace_delta_ms:
--   A negative number means that fitness band was, on average, that many
--   milliseconds FASTER than the race's own average clean lap. A positive
--   number means slower. 1000 ms = 1 second.
