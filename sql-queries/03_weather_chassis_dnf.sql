-- =====================================================================
-- Q3: Does weather or chassis age predict a DNF (did-not-finish)?
-- =====================================================================
-- Business question:
--   Race strategists want to know two things going into a weekend:
--   (1) how much extra DNF risk does rain add, and (2) does a chassis
--   get more failure-prone the more races it has run, independent of
--   weather?
--
-- Approach:
--   Part A is a straight group-by: DNF rate per weather condition.
--   Part B uses a window function (ROW_NUMBER) to count, for each car,
--   which race in its own career this one is -- its "chassis age" in
--   races -- then buckets that age and compares DNF rates across
--   buckets. This isolates wear-and-tear from any single race's
--   weather, because every bucket mixes dry and wet races.
-- =====================================================================

SET search_path TO apex;

-- Part A: DNF rate by weather
SELECT
    r.weather,
    COUNT(*)                                              AS total_entries,
    SUM(CASE WHEN e.dnf THEN 1 ELSE 0 END)                AS dnf_count,
    ROUND(100.0 * SUM(CASE WHEN e.dnf THEN 1 ELSE 0 END) / COUNT(*), 1) AS dnf_rate_pct
FROM race_entries e
JOIN races r ON r.race_id = e.race_id
GROUP BY r.weather
ORDER BY dnf_rate_pct DESC;

-- Part B: DNF rate by chassis age (races run on that car so far)
WITH car_age AS (
    SELECT
        e.entry_id,
        e.car_id,
        e.dnf,
        ROW_NUMBER() OVER (
            PARTITION BY e.car_id
            ORDER BY r.race_date
        ) AS races_on_this_chassis   -- 1 = the car's debut race
    FROM race_entries e
    JOIN races r ON r.race_id = e.race_id
),
age_bucketed AS (
    SELECT
        CASE
            WHEN races_on_this_chassis <= 5  THEN '1-5 races (new)'
            WHEN races_on_this_chassis <= 10 THEN '6-10 races (mid)'
            ELSE '11+ races (high mileage)'
        END AS chassis_age_bucket,
        dnf
    FROM car_age
)
SELECT
    chassis_age_bucket,
    COUNT(*)                                          AS total_entries,
    SUM(CASE WHEN dnf THEN 1 ELSE 0 END)               AS dnf_count,
    ROUND(100.0 * SUM(CASE WHEN dnf THEN 1 ELSE 0 END) / COUNT(*), 1) AS dnf_rate_pct
FROM age_bucketed
GROUP BY chassis_age_bucket
ORDER BY chassis_age_bucket;