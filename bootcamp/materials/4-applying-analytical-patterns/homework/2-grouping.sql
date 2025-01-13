-- Create a temporary table for the GROUPING SETS results
-- DROP TABLE IF EXISTS temp_grouping_sets;

CREATE TEMPORARY TABLE temp_grouping_sets AS
SELECT
    gd.player_name,
    gd.player_id,
    gd.team_id,
    g.season,
    SUM(COALESCE(gd.pts, 0)) AS total_points,
    SUM(COALESCE(g.home_team_wins, 0)) AS total_wins
FROM game_details gd
LEFT JOIN games g ON gd.game_id = g.game_id
GROUP BY GROUPING SETS (
    (player_name, player_id, team_id),
    (player_name, player_id, season),
    (team_id)
);

SELECT * FROM temp_grouping_sets limit 10;

-- Retrieve the player who scored the most points by team
SELECT 
    tgs.player_name,
    tgs.team_id,
    tgs.player_name,
    tgs.player_id,
    t.abbreviation as team_name,
    tgs.total_points AS max_points
FROM temp_grouping_sets tgs
-- LEFT JOIN players p ON tgs.player_name = p.player_name
LEFT JOIN teams t ON tgs.team_id = t.team_id
WHERE tgs.player_name IS NOT NULL AND tgs.team_id IS NOT NULL
ORDER BY tgs.total_points DESC
LIMIT 1;


-- Retrieve the player who scored the most points by season
SELECT 
    tgs.season,
    tgs.player_name,
    tgs.total_points AS max_points
FROM temp_grouping_sets tgs
WHERE tgs.player_name IS NOT NULL AND tgs.season IS NOT NULL
ORDER BY tgs.total_points DESC
LIMIT 1;


-- Retrieve the team with the most wins
SELECT 
    tgs.team_id,
    t.abbreviation as team_name,
    tgs.total_wins AS max_wins
FROM temp_grouping_sets tgs
LEFT JOIN teams t ON tgs.team_id = t.team_id
WHERE tgs.team_id IS NOT NULL AND tgs.player_id IS NULL AND tgs.season IS NULL
ORDER BY tgs.total_wins DESC
LIMIT 1;