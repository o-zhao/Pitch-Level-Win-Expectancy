--------------------------------------------------------DATABASE MODIFICATION/CLEANING-----------------------------------

----------Uncomment -> Only run this part once #YORO


--Make binary base states

/*ALTER TABLE pitch
ADD Occupied1b
DEFAULT NULL

/*ALTER TABLE pitch
ADD Occupied2b
DEFAULT NULL 

/*ALTER TABLE pitch
ADD Occupied3b
DEFAULT NULL

/*UPDATE pitch
SET Occupied1b = CASE
WHEN on_1b IS NULL THEN 0
ELSE 1
END;

/*UPDATE pitch
SET Occupied2b = CASE
WHEN on_2b IS NULL THEN 0
ELSE 1
END;

/*UPDATE pitch
SET Occupied3b = CASE
WHEN on_3b IS NULL THEN 0
ELSE 1
END;

--Create ID to join game table

/*UPDATE game
SET gameday_link = 'gid_' || gameday_link

--Fiddling to order row numbercorrectly cause SQLite can't even do row number right smh

/*CREATE TABLE stupidID AS 
SELECT * FROM atbat ORDER BY gameday_link ASC, num ASC;
ALTER TABLE stupidID
ADD rownum
DEFAULT _ROWID_
UPDATE stupidID 
SET rownum = _ROWID_

--Filling in null values of score

/*UPDATE stupidID
SET home_team_runs = 0
WHERE num = 1;

/*UPDATE stupidID
SET away_team_runs = 0
WHERE num = 1;

/*CREATE TABLE SortedData AS
    SELECT
       gameday_link, num, rownum, home_team_runs, away_team_runs
    FROM stupidID
    ORDER BY rownum ASC;
    
    
UPDATE SortedData
SET home_team_runs = (SELECT home_team_runs
             FROM SortedData AS sd2
             WHERE (sd2.rownum < SortedData.rownum AND sd2.home_team_runs IS NOT NULL)
             ORDER BY rownum DESC 
             LIMIT 1)
WHERE
    SortedData.home_team_runs IS NULL;


/*UPDATE SortedData
SET away_team_runs = (SELECT away_team_runs
             FROM SortedData AS sd2
             WHERE (sd2.rownum < SortedData.rownum AND sd2.away_team_runs IS NOT NULL)
             ORDER BY rownum DESC 
             LIMIT 1)
WHERE
    SortedData.away_team_runs IS NULL;
   
--Joinig updated values
 
/*UPDATE stupidID 
SET home_team_runs = (SELECT sd.home_team_runs FROM SortedData as sd INNER JOIN stupidID as id ON (sd.gameday_link = id.gameday_link and sd.num = id.num))

/*UPDATE stupidID 
SET away_team_runs = (SELECT sd.away_team_runs FROM SortedData as sd INNER JOIN stupidID as id ON (sd.gameday_link = id.gameday_link and sd.num = id.num))


--ALTERNATE TO UPDATE RUNS CAUSE APPARENTLY INNER JOINS DON'T WORK WITHIN UPDATE EVEN THOUGH IT DEFINITELY DID SO SQL LIKES TO GASLIGHT ME AND RUIN MY LIFE???

/*UPDATE atbat 
SET home_team_runs = (SELECT home_team_runs FROM SortedData WHERE atbat.rownum = SortedData.rownum)

/*UPDATE atbat 
SET away_team_runs = (SELECT away_team_runs FROM SortedData WHERE atbat.rownum = SortedData.rownum)


/*DROP TABLE atbat;

/*ALTER TABLE stupidID RENAME TO atbat;

--Creating remaining outs for offense/defense

/*ALTER TABLE atbat
ADD off_rem_outs_h
DEFAULT NULL;

/*UPDATE atbat
SET off_rem_outs_h = 27-(inning*3)-3+o
WHERE inning_side = "bottom";

/*UPDATE atbat
SET off_rem_outs_h = 27-(inning-1)*3
WHERE inning_side = "top";

/*ALTER TABLE atbat
ADD def_rem_outs_h
DEFAULT NULL;

/*UPDATE atbat
SET def_rem_outs_h = 27-((inning-1)*3)-o
WHERE inning_side = "top";

/*UPDATE atbat
SET def_rem_outs_h = 27-inning*3
WHERE inning_side = "bottom";

------------------------------------------JOINING AND GROUPING TO CREATE WIN EXPECTANCY INDEX-----------------------------------------------


------Joins pitch, atbat, and game for all information down to each pitch level. Then groups by states. Written to table in order to be used with R.

CREATE TABLE WinEx AS 
SELECT p.inning_side AS side,
       p.inning AS inn,
       substr(count,1,1) AS b,
       substr(count,3,4) AS s,
       atbat.o AS out,
       p.Occupied1b AS state_1b,
       p.Occupied2b AS state_2b,
       p.Occupied3b AS state_3b,
       (CAST(atbat.home_team_runs AS INT) - CAST(atbat.away_team_runs AS INT)) AS rd,
       (CAST(SUM(game.homeW) AS float)/ CAST(COUNT( * ) AS float)) AS w_Pct,
       atbat.off_rem_outs_h AS off_r_outs,
       atbat.def_rem_outs_h AS def_r_outs,
       count( * ) AS n
  FROM pitch AS p
       INNER JOIN
       atbat ON (p.gameday_link = atbat.gameday_link AND 
                 p.num = atbat.num) 
       INNER JOIN
       game ON atbat.gameday_link = game.gameday_link
   --WHERE atbat.gameday_link = "gid_2010_04_02_chamlb_atlmlb_1"
 GROUP BY side,
          inn,
          count,
          out,
          Occupied1b,
          Occupied2b,
          Occupied3b,
          rd
 ORDER BY inn ASC,
          side DESC,
          rd ASC;



--------------------------------------------------------------------------------
