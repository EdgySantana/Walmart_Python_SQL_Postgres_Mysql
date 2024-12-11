-- View all the data in the Walmart dataset
SELECT * FROM walmart;

-- How many records are there in the dataset?
SELECT COUNT(*) AS total_records FROM walmart;

-- Business Related questions:
-- Q.1 What are the different payment methods used in the Walmart dataset, 
-- and how many transactions are associated with each method?
SELECT
    payment_method,
    COUNT(*) AS transaction_count
FROM walmart
GROUP BY payment_method;

-- Q.2 How many unique branches are in the dataset?
SELECT 
    COUNT(DISTINCT branch) AS unique_branches
FROM walmart;

-- Q.3 What is the maximum quantity of items sold in a single transaction?
SELECT MAX(quantity) AS max_quantity_sold
FROM walmart;

-- Q.4 What is the average quantity of items sold per transaction in the Walmart dataset?
SELECT AVG(quantity) AS avg_quantity_sold
FROM walmart;

-- Q.5 Find different payment methods and 
-- number of transactions, 
-- number of quantities sold
SELECT
    payment_method,
    COUNT(*) AS number_of_transactions,
    SUM(quantity) AS total_quantity_sold
FROM walmart
GROUP BY payment_method;

-- Q.6 Identify the highest-rated category in each branch based on average ratings.
-- Use AVG and window function RANK (MySQL 8.0+ required for window functions).
SELECT
    branch,
    category,
    ROUND(AVG(rating), 2) AS avg_rating,
    RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
FROM walmart
GROUP BY branch, category
ORDER BY branch, avg_rating DESC;

-- Find the top-ranked category for each branch using a subquery.
SELECT *
FROM (
    SELECT
        branch, 
        category,  
        ROUND(AVG(rating), 2) AS avg_rating,
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart
    GROUP BY branch, category
) AS ranked_categories
WHERE rank = 1;

-- Q.7 Identify the busiest day for each branch based on the number of transactions.
SELECT branch, 
       DATE_FORMAT(date, '%W') AS day_of_week, 
       COUNT(*) AS number_of_transactions
FROM walmart
GROUP BY branch, DATE_FORMAT(date, '%W')
ORDER BY branch, number_of_transactions DESC;

-- Q.8 Determine the average, minimum, and maximum rating of categories of products for each city.
SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    ROUND(AVG(rating), 1) AS avg_rating
FROM walmart
GROUP BY city, category;

-- Q.9 Calculate the total profit for each category, considering total profit as unit_price * quantity * profit_margin.
SELECT
    category,
    ROUND(SUM(total), 0) AS total_revenue,
    ROUND(SUM(unit_price * quantity * profit_margin), 0) AS total_profit
FROM walmart
GROUP BY category;

-- Q.10 Find the preferred payment method for each branch based on the total number of transactions.
SELECT branch, 
       payment_method,
       COUNT(invoice_id) AS transaction_count
FROM walmart
GROUP BY branch, payment_method
ORDER BY branch, transaction_count DESC;

-- Q.11 Categorize sales into Morning, Afternoon, Evening, and calculate transaction counts per branch and shift.
WITH categorized_shifts AS (
    SELECT
        branch,
        CASE
            WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
            WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift,
        invoice_id
    FROM walmart
)
SELECT
    branch,
    shift,
    COUNT(invoice_id) AS transaction_count
FROM categorized_shifts
GROUP BY branch, shift
ORDER BY branch, shift;

-- Q.12 Identify 5 branches with the highest revenue decrease ratio from 2022 to 2023.
WITH revenue_2022 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(DATE(date)) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(DATE(date)) = 2023
    GROUP BY branch
)
SELECT 
    r22.branch,
    r22.revenue AS revenue_2022,
    r23.revenue AS revenue_2023,
    ROUND(((r22.revenue - r23.revenue) / r22.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r22
JOIN revenue_2023 AS r23
    ON r22.branch = r23.branch
WHERE r22.revenue > r23.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;

-- Q.13 Determine the top 3 busiest days for each branch based on the number of transactions.
WITH ranked_days AS (
    SELECT branch,
           DATE_FORMAT(date, '%W') AS day_name,
           COUNT(*) AS num_transactions,
           RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, day_name
)
SELECT branch, day_name, num_transactions
FROM ranked_days
WHERE rank <= 3
ORDER BY branch, rank;

-- Q.14 What is the revenue contribution percentage of each category to its respective branch?
WITH total_branch_revenue AS (
    SELECT branch, SUM(total) AS branch_revenue
    FROM walmart
    GROUP BY branch
)
SELECT
    w.branch,
    w.category,
    SUM(w.total) AS category_revenue,
    ROUND((SUM(w.total) / t.branch_revenue) * 100, 1) AS revenue_percentage
FROM walmart w
JOIN total_branch_revenue t ON w.branch = t.branch
GROUP BY w.branch, w.category, t.branch_revenue;

-- Q.15 What are the total sales for the top 3 categories per branch? (Displayed as columns)
SELECT branch,
       SUM(CASE WHEN category = 'Electronic accessories' THEN total ELSE 0 END) AS electronics_sales,
       SUM(CASE WHEN category = 'Sports and travel' THEN total ELSE 0 END) AS sports_sales,
       SUM(CASE WHEN category = 'Health and beauty' THEN total ELSE 0 END) AS health_sales
FROM walmart
GROUP BY branch;

--Q.16 Question: What is the cumulative revenue for each branch, ordered by transaction date?
-- Window Function with Cumulative Totals

-- Step 1: Get the top 5 branches based on total revenue
WITH branch_totals AS (
    SELECT branch, SUM(total) AS total_revenue
    FROM walmart
    GROUP BY branch
    ORDER BY total_revenue DESC
    LIMIT 5
)

-- Step 2: Calculate cumulative revenue for only the top 5 branches
SELECT 
    w.branch,
    STR_TO_DATE(w.date, '%d/%m/%y') AS transaction_date,
    ROUND(
        SUM(w.total) OVER (
            PARTITION BY w.branch
            ORDER BY STR_TO_DATE(w.date, '%d/%m/%y')
        ),
        0
    ) AS cumulative_revenue
FROM walmart w
WHERE w.branch IN (SELECT branch FROM branch_totals)
ORDER BY w.branch, STR_TO_DATE(w.date, '%d/%m/%y');

-- Q.17 What are the total sales for each category, displayed as columns for easier comparison?
-- Use of Pivoting

SELECT 
    branch,
    ROUND(SUM(CASE WHEN category = 'Electronic accessories' THEN total ELSE 0 END), 0) AS electronics_sales, 
    ROUND(SUM(CASE WHEN category = 'Sports and travel' THEN total ELSE 0 END), 0) AS sports_travel_sales,      
    ROUND(SUM(CASE WHEN category = 'Health and beauty' THEN total ELSE 0 END), 0) AS health_beauty_sales       
FROM walmart
GROUP BY branch;

-- This simulates a pivot table in SQL and is great for cross-category comparisons in a concise format.


