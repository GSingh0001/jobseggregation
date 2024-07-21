USE hib_assignment;

-- Top 10 Naics
SELECT 
    n.naics_code_3d,
    n.naics_title AS industry,
    COUNT(*) AS num_of_approved_applications
FROM
    visa_cases v
        JOIN
    naics_codes n ON v.naics_code_3d = n.naics_code_3d
WHERE
    v.case_status = 'Certified'
GROUP BY n.naics_code_3d , industry
ORDER BY num_of_approved_applications DESC
LIMIT 10
;
-- ----------------------------------------------------------------------

-- Top states  

SELECT 
  state_id,
  state_name AS state_name,
  quality_index,
  (med_income-med_income_after_tax)/med_income as spending_power,
  layoffs_k
FROM 
  state
  
ORDER BY 
  spending_power DESC, 
  layoffs_k
;

-- -------------------------------------------------

SELECT 
    s.state_id,
    s.state_name,
    s.quality_index,
    s.med_income_after_tax,
    s.layoffs_k,
    (med_income-med_income_after_tax)/med_income as spending_power,
    COUNT(v.visa_case_id) AS Total_applications,
    (COUNT(CASE
        WHEN v.case_status = 'Certified' THEN 1
    END)) AS Approved_applications,
    ((COUNT(CASE
        WHEN v.case_status = 'Certified' THEN 1
    END) / COUNT(*)) * 100) AS approval_rate
FROM
    visa_cases v
        LEFT JOIN
    cities c ON c.city_id = v.city_id
        LEFT JOIN
    state s ON s.state_id = c.state_id
GROUP BY spending_power,s.state_id , s.state_name , s.quality_index , s.med_income_after_tax , s.layoffs_k
ORDER BY spending_power DESC
;

-- ------------------------------------------------------------------------
SELECT 
  soc.soc_code,
  soc.soc_title,
  v.salary_job,
  SUM(CASE WHEN v.case_status = 'CERTIFIED' AND v.begin_date < '2022-06-01' THEN 1 ELSE 0 END) AS certified_before_Jun_2022,
  SUM(CASE WHEN v.begin_date < '2022-06-01' THEN 1 ELSE 0 END) AS total_before_Jun_2022,
  IF(SUM(CASE WHEN v.begin_date < '2022-06-01' THEN 1 ELSE 0 END) > 0, 
     SUM(CASE WHEN v.case_status = 'CERTIFIED' AND v.begin_date < '2022-06-01' THEN 1 ELSE 0 END) / 
     SUM(CASE WHEN v.begin_date < '2022-06-01' THEN 1 ELSE 0 END), 
     0) AS approval_rate_before_Jun_2022,
  SUM(CASE WHEN v.case_status = 'CERTIFIED' AND v.begin_date >= '2022-06-01' THEN 1 ELSE 0 END) AS certified_after_Jun_2022,
  SUM(CASE WHEN v.begin_date >= '2022-06-01' THEN 1 ELSE 0 END) AS total_after_Jun_2022,
  IF(SUM(CASE WHEN v.begin_date >= '2022-06-01' THEN 1 ELSE 0 END) > 0, 
     SUM(CASE WHEN v.case_status = 'CERTIFIED' AND v.begin_date >= '2022-06-01' THEN 1 ELSE 0 END) / 
     SUM(CASE WHEN v.begin_date >= '2022-06-01' THEN 1 ELSE 0 END), 
     0) AS approval_rate_after_Jun_2022
FROM visa_cases v
LEFT JOIN soc_codes soc ON v.soc_code = soc.soc_code
GROUP BY soc.soc_code, soc.soc_title, v.salary_job
ORDER BY v.salary_job
;

--     -----------------------------------------------------

SELECT 
    soc.soc_title AS Job_Function,
    COUNT(DISTINCT j.job_id) AS Number_of_Openings,
    ROUND(AVG(v.starting_salary), 2) AS Average_Salary,
    ROUND(SUM(CASE WHEN v.case_status = 'Certified' THEN 1 ELSE 0 END) / COUNT(v.visa_case_id) * 100, 2) AS Approval_Rate
FROM visa_cases v
INNER JOIN jobs j ON v.job_id = j.job_id
INNER JOIN soc_codes soc ON soc.soc_code = v.soc_code
WHERE v.case_status = 'Certified'
GROUP BY Job_Function
;

-- Top Functions--------------------

SELECT 
    soc.soc_title AS Job_Function,
    COUNT(v.job_id) AS Number_of_Openings,
    AVG(v.starting_salary) AS Average_Salary,
    SUM(CASE
        WHEN v.case_status = 'Certified' THEN 1
        ELSE 0
    END) / COUNT(*) * 100 AS Approval_Rate
FROM
    visa_cases v
        INNER JOIN
    jobs j ON v.job_id = j.job_id
        INNER JOIN
    soc_codes soc ON v.soc_code = soc.soc_code
WHERE
    v.decision_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY soc.soc_title
HAVING Number_of_Openings >=30
ORDER BY  Average_Salary DESC;

-- ----------------------------------

SELECT 
    s.state_name,
    n.industry AS Job_Function,
    COUNT(v.job_id) AS Job_Count,
    ROUND(AVG(v.starting_salary), 2) AS Average_Salary,
    ROUND(SUM(CASE
                WHEN v.case_status = 'Certified' THEN 1
                ELSE 0
            END) / COUNT(v.visa_case_id) * 100,
            2) AS Approval_Rate
FROM
    state s
        LEFT JOIN
    cities c ON s.state_id = c.state_id
        LEFT JOIN
    visa_cases v ON v.city_id = c.city_id
        LEFT JOIN
    jobs j ON v.job_id = j.job_id
        LEFT JOIN
    soc_codes soc ON v.soc_code = soc.soc_code
        INNER JOIN
    (SELECT 
        state_id,
            state_name AS state_name,
            quality_index,
            (med_income - med_income_after_tax) / med_income AS spending_power,
            layoffs_k
    FROM
        state
    ORDER BY spending_power DESC , layoffs_k
    LIMIT 5) AS r ON r.state_id = s.state_id
		INNER JOIN
	(SELECT 
    n.naics_code_3d,
    n.naics_title AS industry,
    COUNT(*) AS num_of_approved_applications
FROM
    visa_cases v
        inner JOIN
    naics_codes n ON v.naics_code_3d = n.naics_code_3d
WHERE
    v.case_status = 'Certified'
GROUP BY n.naics_code_3d , industry
ORDER BY num_of_approved_applications DESC
LIMIT 5) AS n on n.naics_code_3d=v.naics_code_3d
GROUP BY n.industry , s.state_name
ORDER BY s.state_name , Approval_rate DESC
;