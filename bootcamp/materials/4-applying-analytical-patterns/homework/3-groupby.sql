-- Retrieve games with related details
SELECT *
FROM game_details gd
LEFT JOIN games g ON gd.game_id = g.game_id
LIMIT 1000;

-- 3.1 - Most games a team has won in a 90-game stretch
WITH cte_cumulated_points AS (
    SELECT
        game_date_est,
        home_team_id,
        home_team_wins,
        SUM(home_team_wins) OVER (
            PARTITION BY home_team_id
            ORDER BY game_date_est
        ) AS running_total_points
    FROM games
), cte_points_in_stretch_period AS (
    SELECT
        game_date_est,
        home_team_id,
        home_team_wins,
        running_total_points - COALESCE(
            LAG(running_total_points, 90) OVER (
                PARTITION BY home_team_id
                ORDER BY game_date_est
            ), 0
        ) AS points_in_stretch_period
    FROM cte_cumulated_points
)
SELECT
    home_team_id,
    MAX(points_in_stretch_period) AS max_won_games_per_team
FROM cte_points_in_stretch_period
GROUP BY home_team_id;

-- 3.2 - Consecutive games where LeBron James scored over 10 points
WITH cte_more_than_10_points AS (
    SELECT
        g.game_date_est,
        gd.player_id,
        gd.player_name,
        gd.pts,
        CASE
            WHEN gd.pts IS NULL OR gd.pts < 11 THEN 1
            ELSE 0
        END AS points_over_10
    FROM game_details gd
    LEFT JOIN games g ON gd.game_id = g.game_id
    WHERE gd.player_name = 'LeBron James'
), cte_cumulated_points AS (
    SELECT
        *,
        CASE
            WHEN points_over_10 = 1 THEN -1
            ELSE SUM(points_over_10) OVER (
                ORDER BY game_date_est
            )
        END AS cumulative_sum
    FROM cte_more_than_10_points
)
SELECT
    MIN(game_date_est) AS start_date,
    MAX(game_date_est) AS end_date,
    MAX(player_id) AS player_id,
    MAX(player_name) AS player_name,
    COUNT(cumulative_sum) AS consecutive_games
FROM cte_cumulated_points
WHERE cumulative_sum >= 0
GROUP BY cumulative_sum
HAVING COUNT(cumulative_sum) > 1
ORDER BY COUNT(cumulative_sum) DESC;
