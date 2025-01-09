-- Get names instead of IDs by joining with the game table
WITH cte_grouping_sets AS (
    SELECT
        gd.player_id,
        gd.team_id,
        g.season,
        SUM(COALESCE(gd.pts, 0)) AS total_points,
        SUM(COALESCE(g.home_team_wins, 0)) AS total_wins
    FROM game_details gd
    LEFT JOIN games g ON gd.game_id = g.game_id
    GROUP BY GROUPING SETS (
        (player_id, team_id),
        (player_id, season),
        (team_id)
    )
),
scored_most_points_by_team_id AS (
    SELECT player_id, total_points
    FROM cte_grouping_sets
    WHERE player_id IS NOT NULL AND team_id IS NOT NULL
    ORDER BY total_points DESC
    LIMIT 1
),
scored_most_points_by_season AS (
    SELECT player_id, total_points
    FROM cte_grouping_sets
    WHERE player_id IS NOT NULL AND season IS NOT NULL
    ORDER BY total_points DESC
    LIMIT 1
),
team_has_won_most_games AS (
    SELECT team_id, total_wins
    FROM cte_grouping_sets
    WHERE team_id IS NOT NULL AND player_id IS NULL AND season IS NULL
    ORDER BY total_wins DESC
    LIMIT 1
)
SELECT *
FROM team_has_won_most_games;
