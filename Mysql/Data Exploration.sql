
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (1) Display the first and last names of all the team leads. Do not repeat names if a staff member has been a team lead more than once.
*/

SELECT DISTINCT first_name, last_name
FROM staff
WHERE id IN 
	(SELECT staff_id
	FROM profile LEFT JOIN role
	ON role_id = id
	WHERE role_name = 'team Lead');

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (2) Show all staff who have ever worked for a Victorian team. Show their name and team.  
		Display the list sorted alphabetically by last name.
*/

SELECT DISTINCT staff.last_name, staff.first_name, team.team_name
FROM profile
INNER JOIN team ON profile.team_id=team.id
INNER JOIN staff ON profile.staff_id=staff.id
INNER JOIN team parent_team ON team.parent_id = parent_team.id
WHERE parent_team.team_name = 'Victoria'
ORDER BY staff.last_name;

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (3) Show staff who worked in Errinundra at any time between 13th April and 13th May.
		Display their first and last name
*/

SELECT first_name, last_name
FROM staff 
WHERE id IN 
	(SELECT staff_id 
	FROM profile NATURAL JOIN team
	WHERE team.id = team_id 
	AND team_name = 'Errinundra'
	AND DATE(valid_from) <= '2021-05-13' 
	AND DATE(valid_until) >= '2021-04-13');

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (4) Which agents (Not including team leaders) were working only in Werrikimbe (and no other team) on 23th of May? Show their name.
*/

SELECT first_name, last_name
FROM staff NATURAL JOIN profile
WHERE staff.id = staff_id
AND role_id = 
	(SELECT id
	FROM role
	WHERE role_name = 'Agent')
AND DATE(valid_from) <= '2021-05-23' 
AND DATE(valid_until) >= '2021-05-23'
AND staff.id NOT IN 
	(SELECT staff_id
	FROM team NATURAL JOIN profile 
	WHERE team.id = team_id
		AND team_name <> 'Werrikimbe'
		AND DATE(valid_from) <= '2021-05-23' 
		AND DATE(valid_until) >= '2021-05-23' 
		AND role_id = 
			(SELECT id
			FROM role
			WHERE role_name = 'Agent'));

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (5) Calculate the monthly average agent quality (AQ) score for each team. 
		Display the team name, month and average AQ sorted by average AQ so that the highest scoring teams are listed first.
*/

SELECT team_name, MONTH(response_time) AS month, 
	AVG(agent_quality) AS averageAQ
FROM profile NATURAL JOIN survey_response 
	LEFT JOIN team ON team.id = team_id
GROUP BY team_name, month
ORDER BY averageAQ DESC ;

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/*  (6) The business want to know how their Net Promoter Score (NPS) is tracking.  
		Calculate the NPS of the organisation for the months of April, May and June 2021. 
		Display the month and NPS value sorted in increasing order of month.
*/

SELECT MONTH(response_time) AS month, 
	(SUM(CASE 
		WHEN promoter_score >= 9
		THEN 1 
		ELSE 0 
	END)
	- SUM(CASE 
		WHEN promoter_score <= 6 
        THEN 1 
        ELSE 0 
	END))
    /COUNT(*)*100 AS NPS
FROM survey_response
WHERE id IN 
	(SELECT id 
    FROM survey_response
	WHERE promoter_score IS NOT NULL)
GROUP BY month
ORDER BY month;

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
/* (7) "Enhanced" participation is similar to participation, but considers not just offered surveys, but offered surveys with
    at least one question - the first - answered by the customer.	
*/

SELECT SUM(CASE
	WHEN first_call_resolution IS NOT NULL 
		THEN 1 
        ELSE 0 
	END)
	/COUNT(*) AS Tatjanas_enhanced_participation
FROM call_record NATURAL JOIN profile 
	LEFT JOIN survey_response ON id = survey_response_id
WHERE MONTH(call_time) = 6
	AND staff_id = 
		(SELECT id 
		FROM staff
		WHERE first_name = 'Tatjana'
		AND last_name = 'Pryor');

-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

SELECT first_name, last_name, COUNT(*) AS FCR_count
FROM survey_response NATURAL JOIN profile 
	LEFT JOIN staff ON staff_id = staff.id
WHERE first_call_resolution = 2
	AND DATE(response_time) <= '2021-06-17' 
	AND DATE(response_time) >= '2021-06-01'
GROUP BY staff_id
HAVING COUNT(*) = 
	(SELECT MIN(mycount) FROM 
						(select staff_id, count(*) as mycount
						from survey_response NATURAL JOIN profile 
							LEFT JOIN staff ON staff_id = staff.id
						WHERE first_call_resolution = 2
							AND DATE(response_time) <= '2021-06-17' 
							AND DATE(response_time) >= '2021-06-01'
						GROUP BY staff_id) b);

-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT AVG(CASE
	WHEN call_ref in 
		(SELECT call_ref
		FROM profile NATURAL JOIN call_record
			LEFT JOIN survey_response ON survey_response_id = survey_response.id
		WHERE call_leg >1
			AND role_id = (SELECT id
							FROM role
							WHERE role_name = 'team Lead'))
	THEN agent_quality
	ELSE NULL
END) AS averageAQ_with_leader,
    AVG(agent_quality) AS overall_averageAQ
FROM profile NATURAL JOIN call_record 
	LEFT JOIN survey_response ON survey_response_id = survey_response.id;

-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT first_name, last_name
FROM profile LEFT JOIN staff ON staff.id = staff_id
WHERE staff_id NOT IN 
	(SELECT DISTINCT staff_id
	FROM profile 
	WHERE team_id IN
		(SELECT DISTINCT team_id
		FROM profile LEFT JOIN staff ON staff_id = staff.id
		WHERE first_name = 'Tatjana'
		AND last_name = 'Pryor'))
GROUP BY staff_id
HAVING COUNT(DISTINCT team_id) = 
	(SELECT COUNT(*) 
    FROM team
    WHERE has_staff <> 0)
	-(SELECT COUNT(DISTINCT team_id)
	FROM profile LEFT JOIN staff ON staff_id = staff.id
	WHERE first_name = 'Tatjana'
	AND last_name = 'Pryor');

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line