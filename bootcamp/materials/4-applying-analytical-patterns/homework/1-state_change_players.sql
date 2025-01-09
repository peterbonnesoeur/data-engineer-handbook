-- Create the table to track player state changes
CREATE TABLE state_change_tracking_players (
    player_name TEXT,
    status TEXT,
    season INTEGER,
    PRIMARY KEY (player_name, season)
);

-- DROP TABLE IF EXISTS state_change_tracking_players;
-- Insert updated player statuses into the tracking table
WITH
    last_season AS (
        SELECT *
        FROM state_change_tracking_players
        WHERE season = 2023
    ),
    this_season AS (
        SELECT *
        FROM player_seasons
        WHERE season = 2024
          AND player_name IS NOT NULL
    )
INSERT INTO state_change_tracking_players
SELECT
    COALESCE(ls.player_name, ts.player_name) AS player_name,
    CASE
        WHEN ls.status IS NULL THEN 'New'
        WHEN (ls.status IN ('Retired', 'Stayed Retired')) AND ts.season IS NULL THEN 'Stayed Retired'
        WHEN (ls.status IN ('New', 'Continued Playing', 'Returned from Retirement')) AND ts.season IS NULL THEN 'Retired'
        WHEN (ls.status IN ('Retired', 'Stayed Retired')) AND ts.season IS NOT NULL THEN 'Returned from Retirement'
        WHEN (ls.status IN ('New', 'Continued Playing', 'Returned from Retirement')) AND ts.season IS NOT NULL THEN 'Continued Playing'
        ELSE NULL
    END AS status,
    COALESCE(ls.season + 1, ts.season) AS season
FROM last_season ls
FULL OUTER JOIN this_season ts
ON ls.player_name = ts.player_name;


SELECT * FROM state_change_tracking_players;