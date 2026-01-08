-- Review of Datasets
Select * FROM accounts;
Select * FROM customers;
Select * FROM loans;
Select * FROM payments;
Select * FROM transactions;

-- BASIC SQL

-- How many customers are in each state?
SELECT 
	state,
    count(*) as num_of_customers
FROM 
	customers
GROUP BY 
	state
ORDER BY
	num_of_customers DESC;


-- What’s the average balance of checking vs savings accounts?
SELECT
	(SELECT ROUND(AVG(balance),2) FROM accounts WHERE account_type = 'Checking') as avg_checking_balance,
    (SELECT ROUND(AVG(balance),2) FROM accounts WHERE account_type = 'Savings') as avg_savings_balance
FROM
	accounts
LIMIT 1;


-- Which cities have the highest number of transactions?
SELECT
	city,
    COUNT(*) as transaction_count
FROM
	transactions
GROUP BY
	city
ORDER BY 
	transaction_count DESC;


-- INTERMEDIATE SQL

-- What percentage of customers have both checking and savings accounts?
SELECT
	CONCAT(
		ROUND(
			COUNT(DISTINCT CASE WHEN has_checking = 1 and has_savings = 1 THEN customer_id END) /
            COUNT(DISTINCT customer_id)
        *100,2)
    ,'%') AS checking_and_savings_percent
FROM
	(
	SELECT 
		customer_id,
        MAX(CASE WHEN account_type = 'Checking' THEN 1 ELSE 0 END) as has_checking,
        MAX(CASE WHEN account_type = 'Savings' THEN 1 ELSE 0 END) as has_savings
	FROM
		accounts
	GROUP BY 
		customer_id
	) AS account_summary;


-- Find top 10 customers by total deposits in Q4.
SELECT
	'Q4' AS Quarter,
    c.customer_id,
    ROUND(SUM(t.amount),2) AS total_deposits
FROM
	customers c join accounts a on c.customer_id = a.customer_id join transactions t on a.account_id = t.account_id
WHERE
	t.transaction_type = 'Deposit'
    AND MONTH(transaction_date) IN(10,11,12)
GROUP BY
	c.customer_id
ORDER BY 
	total_deposits DESC
LIMIT 10;    


-- Identify customers with a credit score below 600 who have active loans.
SELECT
	distinct (c.customer_id),
    credit_score
FROM
	customers c JOIN accounts a on c.customer_id = a.customer_id
WHERE
	credit_score < 600 
    AND account_type = 'Loan'
    AND status = 'Active';

-- What is the average loan balance by loan type?
SELECT
	loan_type,
    ROUND(AVG(loan_amount),2) as avg_loan_balance
FROM
	loans
GROUP BY 
	loan_type
ORDER BY
	avg_loan_balance DESC;

-- ADVANCED SQL (Analyst Challenge)

-- Using window functions, rank customers by total transaction volume YTD.
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(amount) DESC) AS total_trans_rank,
	c.customer_id,
    ROUND(SUM(amount),0) as total_trans_amount
FROM
	customers c join accounts a on c.customer_id = a.customer_id join transactions t on a.account_id = t.account_id
WHERE
	YEAR(transaction_date) = 2024
GROUP BY
	c.customer_id;


-- Find customers who missed at least 2 payments in the last 6 months (assuming current month is December 2024).
SELECT 
	l.customer_id,
    COUNT(p.payment_id) as missed_payments
FROM
	payments p join loans l on p.loan_id = l.loan_id
WHERE
	p.payment_status = 'Missed'
    AND p.payment_date BETWEEN '2024-07-01' AND '2024-12-31'
GROUP BY
	l.customer_id
HAVING
	COUNT(p.payment_id) >= 2;


-- Calculate the loan delinquency rate by loan type over time.
SELECT * FROM loans;
SELECT * FROM payments;

SELECT
	date_format(p.payment_date,'%m-%Y') as pay_month,
	CONCAT(ROUND( SUM(CASE WHEN loan_type = 'Auto' AND p.payment_status IN ('Late', 'Missed') THEN 1 ELSE 0 END) 
		/ COUNT(*) * 100, 2),'%') AS auto_delinquency_rate,
	CONCAT(ROUND( SUM(CASE WHEN loan_type = 'Home' AND p.payment_status IN ('Late', 'Missed') THEN 1 ELSE 0 END) 
		/ COUNT(*) * 100, 2),'%') AS home_delinquency_rate,
	CONCAT(ROUND( SUM(CASE WHEN loan_type = 'Business' AND p.payment_status IN ('Late', 'Missed') THEN 1 ELSE 0 END) 
		/ COUNT(*) * 100, 2),'%') AS business_delinquency_rate,
	CONCAT(ROUND( SUM(CASE WHEN loan_type = 'Personal' AND p.payment_status IN ('Late', 'Missed') THEN 1 ELSE 0 END) 
		/ COUNT(*) * 100, 2),'%') AS personal_delinquency_rate
FROM loans l JOIN payments p ON l.loan_id = p.loan_id
WHERE YEAR(p.payment_date) = 2024
GROUP BY pay_month
ORDER BY pay_month;


-- Build a customer lifetime value (CLV) metric combining balances, transactions, and loan repayments.
SELECT
    customer_id,
    customer_name,
    total_balance,
    total_transactions,
    loan_revenue,
    late_payments,
    customer_lifetime_value,
    CASE 
        WHEN customer_lifetime_value >= 100000 THEN 'High Value'
        WHEN customer_lifetime_value >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        ROUND(SUM(a.balance)) AS total_balance,
        COUNT(DISTINCT t.transaction_id) AS total_transactions,
        ROUND(SUM((l.interest_rate/100) * l.loan_amount)) AS loan_revenue,
        SUM(CASE WHEN p.payment_status = 'Late' THEN 1 ELSE 0 END) AS late_payments,
        -- CLV Formula
        ROUND((SUM(a.balance) * 0.2) +
        (COUNT(DISTINCT t.transaction_id) * 2) +
        (SUM((l.interest_rate/100) * l.loan_amount)) -
        (SUM(CASE WHEN p.payment_status = 'Late' THEN 1 ELSE 0 END) * 50))
            AS customer_lifetime_value
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN payments p ON l.loan_id = p.loan_id
    GROUP BY
        c.customer_id, customer_name
) AS clv_calc
ORDER BY customer_lifetime_value DESC;


-- Create a stored procedure to auto-flag “high-risk customers” (low credit, missed payments, low income).
ALTER TABLE customers ADD risk_level VARCHAR(20);

DELIMITER $$

DROP PROCEDURE IF EXISTS update_risk_scores $$
CREATE PROCEDURE update_risk_scores()
BEGIN
  -- Update customers.risk_level using aggregated metrics computed per customer
  UPDATE customers c
  LEFT JOIN (
      SELECT
          c2.customer_id,
          COALESCE(SUM(CASE WHEN p.payment_status = 'Missed' THEN 1 ELSE 0 END), 0) AS missed_count,
          COALESCE(SUM(a.balance), 0) AS total_balance
      FROM 	customers c2
			JOIN loans l2 ON c2.customer_id = l2.customer_id
			JOIN payments p ON l2.loan_id = p.loan_id
			JOIN accounts a ON c2.customer_id = a.customer_id
      GROUP BY c2.customer_id
  ) AS agg ON c.customer_id = agg.customer_id
  SET c.risk_level = CASE
      WHEN agg.missed_count >= 2 OR agg.total_balance < 500 THEN 'High Risk'
      WHEN agg.total_balance BETWEEN 500 AND 5000 THEN 'Medium Risk'
      ELSE 'Low Risk'
  END;
END $$

DELIMITER ;

CALL update_risk_scores();

SELECT * FROM customers;

-- Build a view summarizing customer profitability (deposits + interest – defaults).
DROP VIEW IF EXISTS customer_profitability;
CREATE VIEW customer_profitability AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ROUND(SUM(a.balance)) AS total_deposits,
    ROUND(SUM((l.interest_rate/100) * l.loan_amount)) AS interest_revenue,
    ROUND(SUM(CASE WHEN p.payment_status = 'Late' THEN l.loan_amount * 0.02 ELSE 0 END))
        AS estimated_default_risk,
    ROUND((SUM(a.balance) 
     + SUM((l.interest_rate/100) * l.loan_amount)
     - SUM(CASE WHEN p.payment_status = 'Late' THEN l.loan_amount * 0.02 ELSE 0 END)
    )) AS net_profit
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN loans l ON c.customer_id = l.customer_id
JOIN payments p ON l.loan_id = p.loan_id
GROUP BY c.customer_id, customer_name
ORDER BY net_profit DESC;

SELECT *
from customer_profitability;

-- CTE for Missed payments Past 6 Months
WITH recent_missed AS (
    SELECT
        c.customer_id,
        COUNT(*) AS missed_count
    FROM customers c
    JOIN loans l ON c.customer_id = l.customer_id
    JOIN payments p ON l.loan_id = p.loan_id
    WHERE p.payment_status = 'Missed'
      AND p.payment_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    GROUP BY c.customer_id
)
SELECT *
FROM recent_missed
WHERE missed_count >= 2;


-- Late Payment Trigger Auto-Flag
DELIMITER $$

DROP TRIGGER IF EXISTS late_payment_flag $$
CREATE TRIGGER late_payment_flag
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
  IF NEW.payment_status = 'Missed' THEN
    UPDATE customers c
    JOIN loans l ON c.customer_id = l.customer_id
    SET c.risk_level = 'High Risk'
    WHERE l.loan_id = NEW.loan_id;
  END IF;
END $$

DELIMITER ;



