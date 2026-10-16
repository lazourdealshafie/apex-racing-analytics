-- =====================================================================
-- Q4: Is the team actually improving season over season?
-- =====================================================================
-- Business question:
--   Leadership wants a year-over-year scorecard: are points, wins, and
--   podiums trending up, and which driver is carrying that improvement?
--
-- Approach:
--   Part A aggregates one row per season, then uses the window function
--   LAG() to pull in the *previous* season's points on the same row --
--   without a self-join -- so we can compute a year-over-year delta.
--   Part B ranks drivers within each season by total points using
--   RANK(), so ties share a rank and the next rank skips accordingly
--   (standard motorsport standings behavior).
-- =====================================================================

SET search_path TO apex;

-- Part A: season scorecard with year-over-year change
WITH season_stats AS (
    SELECT
        r.season_year,
        SUM(e.points)                                      AS total_points,
        SUM(CASE WHEN e.finish_position = 1 THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN e.finish_position <= 3 THEN 1 ELSE 0 END) AS podiums,
        SUM(CASE WHEN e.dnf THEN 1 ELSE 0 END)             AS dnfs,
        COUNT(*)                                           AS total_entries
    FROM race_entries e
    JOIN races r ON r.race_id = e.race_id
    GROUP BY r.season_year
)
SELECT
    season_year,
    total_points,
    wins,
    podiums,
    dnfs,
    LAG(total_points) OVER (ORDER BY season_year)          AS prev_season_points,
    total_points - LAG(total_points) OVER (ORDER BY season_year) AS points_change,
    ROUND(
        100.0 * (total_points - LAG(total_points) OVER (ORDER BY season_year))
        / NULLIF(LAG(total_points) OVER (ORDER BY season_year), 0), 1
    )                                                       AS points_change_pct
FROM season_stats
ORDER BY season_year;

-- Part B: driver ranking within each season by points
WITH driver_season AS (
    SELECT
        r.season_year,
        p.first_name || ' ' || p.last_name                 AS driver_name,
        SUM(e.points)                                       AS season_points,
        SUM(CASE WHEN e.finish_position = 1 THEN 1 ELSE 0 END) AS season_wins,
        COUNT(*)                                             AS races_entered
    FROM race_entries e
    JOIN races r      ON r.race_id = e.race_id
    JOIN personnel p  ON p.personnel_id = e.driver_id
    GROUP BY r.season_year, p.first_name, p.last_name
)
SELECT
    season_year,
    driver_name,
    season_points,
    season_wins,
    races_entered,
    RANK() OVER (PARTITION BY season_year ORDER BY season_points DESC) AS points_rank_in_season
FROM driver_season
ORDER BY season_year, points_rank_in_season;
