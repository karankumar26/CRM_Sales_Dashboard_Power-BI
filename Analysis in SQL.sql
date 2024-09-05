create database CRM

USE CRM

SELECT * from accounts
SELECT * from products
SELECT * from sales_pipeline
SELECT * from sales_teams

-- Renaming columns
EXEC sp_rename 'accounts.account', 'company', 'COLUMN'
EXEC sp_rename 'accounts.employees', 'employees_count', 'COLUMN'
EXEC sp_rename 'sales_pipeline.account', 'company', 'COLUMN'


SELECT *
FROM sales_pipeline
WHERE company = 'Individual'

--replace the null values in column company with individual
UPDATE sales_pipeline
SET company = 'Individual'
WHERE company IS NULL;


--Checking for duplicates
SELECT opportunity_id, count(*)
FROM sales_pipeline
GROUP BY opportunity_id
HAVING count(*) > 1
--Found no duplicates


--CRM Sales Opportunities
--B2B sales pipeline data from a fictitious company that sells computer hardware, including information on accounts, products, sales teams, and sales opportunities.


--How is each sales team performing compared to the rest?
SELECT
    st.manager,
    COUNT(sp.opportunity_id) AS total_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS closed_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_sales_value,
    AVG(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE NULL END) AS average_deal_size
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
GROUP BY st.manager;

-- Are any sales agents lagging behind
SELECT
    sp.sales_agent,
    COUNT(sp.opportunity_id) AS total_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS closed_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_sales_value,
    AVG(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE NULL END) AS average_deal_size,
	(SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / COUNT(opportunity_id)) AS close_rate
FROM sales_pipeline sp
GROUP BY sp.sales_agent
ORDER BY total_sales_value


--Can you identify any quarter-over-quarter trends?(Sales quarter over quarter)
WITH QuarterlyMetrics AS (
    SELECT 
        DATEPART(YEAR, sp.close_date) AS year,
        DATEPART(QUARTER, sp.close_date) AS quarter,
        SUM(a.revenue) AS total_closed_value
    FROM sales_pipeline sp
	JOIN accounts a ON sp.company = a.company
    WHERE sp.deal_stage = 'Won' -- Only include won deals
    GROUP BY 
        DATEPART(YEAR, sp.close_date),
        DATEPART(QUARTER, sp.close_date)
),
QuarterlyTrends AS (
    SELECT 
        year,
        quarter,
        total_closed_value,
        LAG(total_closed_value) OVER (ORDER BY year, quarter) AS previous_quarter_value,
        CASE 
            WHEN LAG(total_closed_value) OVER (ORDER BY year, quarter) IS NOT NULL
            THEN (total_closed_value - LAG(total_closed_value) OVER (ORDER BY year, quarter)) * 100.0 / LAG(total_closed_value) OVER (ORDER BY year, quarter)
            ELSE NULL
        END AS growth_percentage
    FROM QuarterlyMetrics
)
SELECT 
    year,
    quarter,
    total_closed_value,
    previous_quarter_value,
    ROUND(growth_percentage, 2) AS growth_percentage
FROM QuarterlyTrends
ORDER BY year, quarter;


--Do any products have better win rates
SELECT
    sp.product,
    COUNT(sp.opportunity_id) AS total_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS closed_opportunities,
    (SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100.0 / COUNT(sp.opportunity_id)) AS win_rate
FROM sales_pipeline sp
GROUP BY sp.product;



SELECT product, count(opportunity_id) as Won_Deals
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY Won_Deals desc

SELECT product, sum(close_value) as Won_Deals
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY Won_Deals desc

SELECT p.series, count(sp.opportunity_id) as Won_Deals
FROM sales_pipeline sp
JOIN products p ON p.product = sp.product
WHERE deal_stage = 'Won'
GROUP BY p.series
ORDER BY Won_Deals desc

SELECT p.series, sum(close_value) as Won_Deals
FROM sales_pipeline sp
JOIN products p ON p.product = sp.product
WHERE deal_stage = 'Won'
GROUP BY p.series
ORDER BY Won_Deals desc