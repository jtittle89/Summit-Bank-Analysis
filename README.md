# Summit-Bank-Analysis
Banking Analysis SQL Project
Project Overview

> This project simulates a real-world banking analytics environment using MySQL and realistic mock financial data. The goal is to demonstrate end-to-end SQL data analysis skills, from database design to advanced analytics, while answering stakeholder-style business questions related to customer behavior, profitability, and credit risk.

The project is designed for a data analyst / analytics / banking analytics portfolio and focuses on writing clean, scalable, and production-style SQL.

> Business Objectives

    As a data analyst supporting a retail bank, this project aims to:
    
    Understand customer financial behavior across accounts, transactions, and loans
    
    Measure customer profitability and lifetime value (CLV)
    
    Identify high-risk customers based on missed payments and balances
    
    Analyze loan delinquency trends by loan type and over time
    
    Provide reusable analytics through views, stored procedures, and triggers
    
    Dataset & Schema

> The database consists of 5 interrelated tables:

    Table	Description
    customers	Customer demographics and risk classification
    accounts	Checking and savings account balances
    transactions	Individual account-level transactions
    loans	Loan details including type, amount, and interest rate
    payments	Monthly loan payment history and payment status
    
    All data is realistic mock data and fully aligned using primary and foreign keys.

> Key SQL Skills Demonstrated

    Relational database design
    
    Complex JOINs across multiple tables
    
    Aggregations and conditional logic (CASE WHEN)
    
    Common Table Expressions (CTEs)
    
    Window functions (ranking, segmentation)
    
    Views for reusable analytics
    
    Stored procedures for automation
    
    Triggers for real-time risk flagging
    
    Date handling and time-based analysis
    
    Error handling with ONLY_FULL_GROUP_BY

> Key Analyses Performed

     Customer Profitability
    
        Combined deposits, transaction activity, loan interest, and late payments
        
        Built a customer profitability view for reporting
        
        Customer Lifetime Value (CLV)
        
        Created a weighted CLV metric using:
        
        Account balances
        
        Transaction volume
        
        Loan interest revenue
        
        Payment behavior penalties
        
        Segmented customers into High / Medium / Low Value tiers
    
    Credit Risk & Delinquency
    
        Calculated delinquency rates by loan type and month
        
        Identified customers missing multiple payments in recent periods
        
        Automatically flagged high-risk customers via stored procedures and triggers

> Automation & Advanced Features

    Stored Procedure to recalculate and update customer risk levels
    
    Trigger to auto-flag customers when a payment status changes to Missed
    
    Views to support repeatable reporting and downstream BI tools

> Example Business Questions Answered

    What percentage of customers have both checking and savings accounts?
    
    Which customers missed 2+ payments in the last 6 months?
    
    How does loan delinquency vary by loan type over time?
    
    Who are the most profitable and highest-risk customers?
