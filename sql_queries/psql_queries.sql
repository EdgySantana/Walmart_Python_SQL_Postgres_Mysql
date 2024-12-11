-- View all the data in the walmart dasaset

SELECT * FROM walmart;

-- How many records are there in the dataset?

SELECT COUNT(*) AS total_records FROM walmart;

-- Business Related questions:
-- Q.1 What are the different payment methods used in the Walmart dataset, 
--and how many transactions are associated with each method?

SELECT
	payment_method,
	COUNT(*)
FROM walmart
GROUP  BY payment_method

-- Q2. How many unique branches are in the dataset?

SELECT 
	COUNT (DISTINCT branch)AS unique_branches
FROM walmart;

-- Q3. What is the maximum quantity of items sold in a single transaction?

SELECT MAX(quantity) 
FROM walmart;

-- Q4. What is the average quantity of items sold per transaction in the walmart dataset?
SELECT AVG(quantity)
FROM walmart;

-- Q.5 Find different payment methods and 
-- number of transactions, 
-- number of quantity sold

SELECT
	payment_method,
	COUNT(*) AS number_of_transactions,
	SUM(quantity) AS quantity_sold
FROM walmart
GROUP  BY payment_method

-- Q.6 Indentify the highest rated category in 
-- each branch
-- category
-- AVG rating

SELECT
	branch,
	category,
	ROUND(AVG(rating::numeric), 2) AS avg_rating,
	RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
FROM walmart
GROUP BY branch, category
ORDER BY branch, avg_rating DESC;

-- Find the #1 rank rated category with a subquery

SELECT *
FROM (
    SELECT
        branch, 
        category,  
        ROUND(AVG(rating::numeric), 2) AS avg_rating,  -- Average rating, rounded to 2 decimal places
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank -- Ranking within each branch
    FROM walmart
    GROUP BY branch, category
) rated_category_per_branch
WHERE rank = 1; -- Filter to get only the top-ranked category per branch

-- Q.7 Indentify the busiest day for each branch based on the number of transactions

SELECT *
FROM 
    (SELECT
        branch,  
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'DAY') AS day_of_week,  -- Day of the week derived from the date
        COUNT(*) AS number_of_transactions,  -- Total transactions for the branch and day
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank -- Rank based on transaction count within each branch
    FROM walmart
    GROUP BY 
        branch, 
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'DAY')
	) 
WHERE rank = 1; -- Filter to get only the top-ranked day for each branch

--Q.8 Determine the average, minimum, and maximum rating of category of products for each city.
--List the city, 
--average_rating
--minimum_rating and 
--max_rating

SELECT
	city,
	category,
	MIN(rating) AS min_rating,
	MAX(rating) AS max_rating,
	ROUND(AVG(rating::numeric), 1) AS avg_rating	
FROM walmart
GROUP BY city, category;

-- Q.9 Calculate the total profit for each category by considering total profit as unit_price multiplied by quantity and profit_margin.
-- List category and total_profit, ordered from highest to lowest profit.
-- Total profit = total_revenue which is(unit_price * quantity) * profit_margin

SELECT
	category,
	ROUND(SUM(total::numeric),0) as total_revenue,
	ROUND(SUM(total::numeric * profit_margin::numeric), 0) as total_profit
FROM walmart
GROUP BY category;

-- Q.10 Find the preferred payment method for each branch based on the total number of transactions
-- Display branch and the preferred payment_method.

WITH preferred_method AS (
    -- Subquery to calculate transaction counts and rank payment methods within each branch
    SELECT
        branch,  
        payment_method,  
        COUNT(invoice_id) AS total_transactions,  -- Total transactions for the payment method in the branch
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) AS rank  -- Rank payment methods by transaction count
    FROM walmart
    GROUP BY 
        branch, 
        payment_method  -- Group by branch and payment method to calculate the counts
)
-- Select the top-ranked payment method for each branch where rank is #1
SELECT *
FROM preferred_method
WHERE rank = 1;  -- Filter to retain only the top-ranked payment method for each branch

--Q.11 Categorize sales into 3 groups: Morning, Afternoon, Evening
-- Determine each of the 3 shifts and number of transaction count per each branch.

-- Categorize shifts into Morning, Afternoon, and Evening and calculate transactions count per branch and shift
-- Categorize shifts and count transactions, listing results from Morning to Evening
-- Categorize shifts in order as: Morning, Afternoon, and Evening using a subquery


WITH categorized_shifts AS (
    SELECT
        branch,  
        CASE 
            WHEN EXTRACT(HOUR FROM time::time) < 12 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM time::time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift,  -- Define shift categories
        invoice_id  -- Retain invoice ID for counting
    FROM walmart
)
SELECT
    branch,  
    shift,  -- Shift categories
    COUNT(invoice_id) AS transaction_count  -- Count transactions per branch and shift
FROM categorized_shifts
GROUP BY 
    branch, 
    shift  -- Group by branch and shift to calculate transaction count.
ORDER BY 
    branch,  -- Sort by branch
    CASE 
        WHEN shift = 'Morning' THEN 1  -- Morning first
        WHEN shift = 'Afternoon' THEN 2  -- Afternoon second
        ELSE 3  -- Evening last
    END, 
    COUNT(invoice_id) DESC;  -- Sort by transaction count in descending order within branch and shift order by:
	-- First Morning as 1, Second Afternoon as 2, lastly Evening as 3 respectively for each branch.

-- Q.12 Identify 5 branches with the highest decrease ratio in 2023 revenue compared to the year prior (2022).
-- Calculate the revenue decrease ratio (or percentage decrease) for branches with revenue decline between 2022 and 2023
-- Compare branch revenues between 2022 and 2023, showing top 5 branches with the largest revenue decline

-- Let's start with formatting of date for year extraction

SELECT *,
EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) as formated_date
FROM walmart

-------------------------------------------------

-- Calculate total revenue per branch for 2022

WITH revenue_2022 AS (
    SELECT 
        branch,  -- Branch identifier
        SUM(total) AS revenue  -- Total revenue for the branch in 2022
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022  -- Filter for transactions in 2022
    GROUP BY branch  -- Group by branch to calculate total revenue
),

-- Calculate total revenue per branch for 2023
revenue_2023 AS (
    SELECT 
        branch,  -- Branch identifier
        SUM(total) AS revenue  -- Total revenue for the branch in 2023
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023  -- Filter for transactions in 2023
    GROUP BY branch  -- Group by branch to calculate total revenue
)

-- Compare revenues and calculate revenue decrease ratio
SELECT 
    ls.branch,  -- Branch identifier
    ls.revenue AS last_year_revenue,  -- Revenue from 2022
    cs.revenue AS cr_year_revenue,  -- Revenue from 2023
    ROUND(
        ((ls.revenue - cs.revenue)::numeric / ls.revenue::numeric) * 100, 
        2
    ) AS rev_decrease_ratio  -- Percentage revenue decrease rounded to 2 decimal places
FROM revenue_2022 AS ls
JOIN revenue_2023 AS cs
    ON ls.branch = cs.branch  -- Join the two revenue tables on branch code.
WHERE 
    ls.revenue > cs.revenue  -- Only include branches with a revenue decrease
ORDER BY rev_decrease_ratio DESC  -- Sort by the largest revenue decrease
LIMIT 5;  -- Show the top 5 branches with the largest revenue decrease

-- Q.13 Determine of the top busiest 3 days per branch

--Query to Get the Top 3 Busiest Days per Branch: 
--use the RANK() or ROW_NUMBER() window function with a PARTITION BY clause, 
--ensuring each branch is treated independently while ranking days based on transaction counts.

WITH ranked_days AS (
    SELECT 
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS num_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, day_name
)
SELECT 
    branch,
    day_name AS busiest_day,
    num_transactions,
	rank
FROM ranked_days
WHERE rank <= 3
ORDER BY branch, rank;

-- Alternative is using ROW_NUMBER():
-- Which breaks ties by assigning ranks sequentially based on the order in which rows are encountered.
-- When the desired outcome is to ensure no ties and have exactly 3 days per branch, RANK() can be replaced
-- with ROW_NUMBER():

WITH ranked_days AS (
    SELECT 
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS num_transactions,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS row_num
    FROM walmart
    GROUP BY branch, day_name
)
SELECT 
    branch,
    day_name AS busiest_day,
    num_transactions,
	row_num
FROM ranked_days
WHERE row_num <= 3
ORDER BY branch, row_num;

-- Q.13.2 What are the top 3 busiest days for each branch, 
-- where days with the same number of transactions share the same rank, 
-- but the ranking does not skip numbers?

WITH ranked_days AS (
    SELECT 
        branch,  -- Branch identifier
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,  -- Extract and format day name
        COUNT(*) AS num_transactions,  -- Count transactions for each branch and day
        DENSE_RANK() OVER (
            PARTITION BY branch  -- Reset ranking for each branch
            ORDER BY COUNT(*) DESC  -- Rank days by transaction count in descending order
        ) AS rank  -- Dense ranking without skipping numbers for ties
    FROM walmart
    GROUP BY branch, day_name  -- Group by branch and day for aggregation
)
SELECT 
    branch,  
    day_name AS busiest_day,  
    num_transactions  -- Number of transactions for the day
FROM ranked_days
WHERE rank <= 3  -- Filter for the top 3 busiest days per branch
ORDER BY branch, rank;  -- Order by branch and rank for readability

-- Q.14 What is the revenue contribution percentage of each category to its respective branch?

WITH total_branch_revenue AS (
    SELECT branch, SUM(total) AS branch_revenue
    FROM walmart
    GROUP BY branch
)
SELECT 
    w.branch,
    w.category,
    ROUND(SUM(w.total::numeric), 0) AS category_revenue,
    ROUND((SUM(w.total)::numeric / t.branch_revenue::numeric) * 100, 1) AS revenue_percentage
FROM walmart w
JOIN total_branch_revenue t ON w.branch = t.branch
GROUP BY w.branch, 
	w.category, 
	t.branch_revenue
ORDER BY 
	branch, 
	revenue_percentage DESC;

-- Q.15 What are the top 3 categories contributing the most to total revenue in each branch?

WITH category_revenue AS (
    SELECT 
        branch, 
        category, 
        ROUND(SUM(total::numeric),0) AS total_revenue
    FROM walmart
    GROUP BY branch, category
)
SELECT *
FROM (
    SELECT 
        branch,
        category,
        total_revenue,
        RANK() OVER (PARTITION BY branch ORDER BY total_revenue DESC) AS rank
    FROM category_revenue
) ranked_categories
WHERE rank <= 3;
 
--Q.16 Question: What is the cumulative revenue for each branch, ordered by transaction date?
-- Window Function with Cumulative Totals

SELECT 
    branch,
    date,
    ROUND(
        SUM(total::numeric) OVER (
            PARTITION BY branch
            ORDER BY TO_DATE(date, 'DD/MM/YY')
        ),
        0
    ) AS cumulative_revenue
FROM walmart
ORDER BY branch, TO_DATE(date, 'DD/MM/YY');
--Demonstrates knowledge of SUM() as a window function.
--This query can be useful for tracking revenue trends over time within each branch.


--Q.17 What are the total sales for each category, displayed as columns for easier comparison?
--Use of Pivoting

SELECT 
    branch,
    ROUND(SUM(CASE WHEN category = 'Electronic accessories' THEN total::numeric ELSE 0 END), 0) AS electronics_sales,
    ROUND(SUM(CASE WHEN category = 'Sports and travel' THEN total::numeric ELSE 0 END), 0) AS grocery_sales,
    ROUND(SUM(CASE WHEN category = 'Health and beauty' THEN total::numeric ELSE 0 END), 0) AS clothing_sales
FROM walmart
GROUP BY branch;

--This simulates a pivot table in SQL and is great for cross-category comparisons in a concise format.