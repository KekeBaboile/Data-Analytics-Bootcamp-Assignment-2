-- =============================================================================
-- Witle Academy Data Analytics Bootcamp
-- Assignment 2: Sizwe Coffee SQL Analysis
-- Student: Keketso Ashley Baboile
-- Student Email: ashleybaboile@gmail.com
-- Database System: Databricks SQL / PostgreSQL
-- =============================================================================

-- =============================================================================
-- Task 1: Channel Performance
-- =============================================================================
SELECT 
    so.channel,
    ROUND(SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END), 2) AS fy2024_revenue,
    ROUND(SUM(CASE WHEN so.order_date > '2024-06-30' THEN sl.line_revenue ELSE 0 END), 2) AS fy2025_revenue,
    ROUND(
        (
            SUM(CASE WHEN so.order_date > '2024-06-30' THEN sl.line_revenue ELSE 0 END) - 
            SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END)
        ) * 100.0 / 
        NULLIF(SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END), 0), 
        2
    ) AS growth_rate_pct
FROM sizwe_sales_orders so
JOIN sizwe_sales_lines sl 
    ON so.order_id = sl.order_id
GROUP BY 
    so.channel
ORDER BY 
    fy2025_revenue DESC;

-- Answer: Total company revenue grew from R440.96M in FY2024 to R480.00M in FY2025 (+8.85%). Growth was driven entirely by the Subscription channel, which surged by +39.31% (R101.69M to R141.67M), while the Wholesale channel experienced a minor contraction of -0.28% (R339.27M to R338.33M).


-- =============================================================================
-- Task 2: Where the Profit Actually Comes From
-- =============================================================================
SELECT 
    p.product_line,
    ROUND(SUM(sl.line_revenue), 2) AS total_revenue,
    ROUND(SUM(sl.cogs), 2) AS total_cogs,
    ROUND(SUM(sl.line_revenue - sl.cogs), 2) AS gross_profit,
    ROUND((SUM(sl.line_revenue - sl.cogs) * 100.0) / NULLIF(SUM(sl.line_revenue), 0), 2) AS gross_margin_pct
FROM sizwe_sales_lines sl
JOIN sizwe_products p 
    ON sl.sku = p.sku
GROUP BY 
    p.product_line
ORDER BY 
    gross_profit DESC;

-- Answer: House Blend earns the highest absolute gross profit at R107.15M (on R279.53M revenue). However, Single Origin yields the highest gross margin percentage at 44.27% (R75.31M gross profit on R170.11M revenue), whereas Bulk Commercial yields the lowest margin at 19.90%.


-- =============================================================================
-- Task 3: The Collections Problem
-- =============================================================================
SELECT 
    c.channel,
    COUNT(a.invoice_no) AS total_invoices,
    COUNT(CASE WHEN a.settlement_date IS NOT NULL THEN 1 END) AS settled_invoices,
    COUNT(CASE WHEN a.settlement_date IS NULL THEN 1 END) AS open_invoices,
    ROUND(AVG(DATEDIFF(a.settlement_date, a.invoice_date)), 1) AS avg_settlement_days,
    ROUND(SUM(a.invoice_amount - COALESCE(a.amount_settled, 0)), 2) AS outstanding_value
FROM sizwe_ar_ledger a
JOIN sizwe_customers c 
    ON a.customer_id = c.customer_id
GROUP BY 
    c.channel
ORDER BY 
    outstanding_value DESC;

-- Answer: The Wholesale channel is the primary collection bottleneck, accumulating R87.85M across 3,454 open invoices with an average settlement time of 68.7 days. By contrast, the Subscription channel settles rapidly (averaging 3.8 days) with only R751.2k outstanding, making Wholesale the clear priority for financial investigation.


-- =============================================================================
-- Task 4: The Ten Accounts That Matter Most
-- =============================================================================
SELECT 
    c.trading_name,
    c.segment,
    c.province,
    COALESCE(r.rep_name, 'No Rep Assigned') AS rep_name,
    ROUND(SUM(sl.line_revenue), 2) AS fy2025_revenue
FROM sizwe_customers c
JOIN sizwe_sales_orders so 
    ON c.customer_id = so.customer_id
JOIN sizwe_sales_lines sl 
    ON so.order_id = sl.order_id
LEFT JOIN sizwe_reps r 
    ON c.rep_id = r.rep_id
WHERE 
    so.order_date > '2024-06-30'
GROUP BY 
    c.trading_name,
    c.segment,
    c.province,
    r.rep_name
ORDER BY 
    fy2025_revenue DESC
LIMIT 10;

-- Answer: Halvane Retail Group is Sizwe Coffee's single largest account by a massive margin, contributing R38.40M in FY2025 revenue. The remaining top 10 accounts represent high-value regional key accounts spanning Grocery, Restaurant Groups, and Cafe networks that require dedicated sales rep oversight.


-- =============================================================================
-- Task 5: A Commercial Gap
-- =============================================================================
SELECT 
    c.trading_name,
    c.segment,
    c.province,
    ROUND(SUM(sl.line_revenue), 2) AS total_revenue
FROM sizwe_customers c
JOIN sizwe_sales_orders so 
    ON c.customer_id = so.customer_id
JOIN sizwe_sales_lines sl 
    ON so.order_id = sl.order_id
LEFT JOIN sizwe_trade_promotions tp 
    ON c.customer_id = tp.customer_id
WHERE 
    c.channel = 'Wholesale'
    AND tp.customer_id IS NULL
GROUP BY 
    c.trading_name,
    c.segment,
    c.province
ORDER BY 
    total_revenue DESC
LIMIT 15;

-- Answer: Sizwe Coffee should immediately assign targeted trade promotions and dedicated sales rep support to top unpromoted accounts like Umhlanga Fresh 108 (R6.22M), Ridgeway Foods 308 (R4.45M), and Kalahari Kitchen 42 (R4.45M) to secure their substantial revenue contributions and prevent churn to competitors.


-- =============================================================================
-- Task 6: Are the Sales Representatives Hitting Target?
-- =============================================================================
SELECT 
    r.rep_name,
    r.territory,
    r.target_monthly AS monthly_target,
    ROUND(COALESCE(SUM(CASE WHEN so.order_date > '2024-06-30' THEN sl.line_revenue ELSE 0 END), 0) / 12.0, 2) AS fy2025_monthly_avg,
    ROUND(
        (COALESCE(SUM(CASE WHEN so.order_date > '2024-06-30' THEN sl.line_revenue ELSE 0 END), 0) / 12.0) * 100.0 / 
        NULLIF(r.target_monthly, 0), 
        2
    ) AS pct_of_target
FROM sizwe_reps r
LEFT JOIN sizwe_sales_orders so 
    ON r.rep_id = so.rep_id
LEFT JOIN sizwe_sales_lines sl 
    ON so.order_id = sl.order_id
GROUP BY 
    r.rep_name,
    r.territory,
    r.target_monthly
ORDER BY 
    pct_of_target DESC;

-- Answer: Out of 18 sales representatives, 16 met or exceeded their monthly FY2025 targets, led by Karabo van Wyk (250.32%) and Kagiso Mkhize (249.82%). Only two representatives fell below target—Sipho Steyn (97.99%) and Johan Naidoo (77.63%)—demonstrating strong commercial performance across almost all territories.


-- =============================================================================
-- Task 7: The Shape of the Year
-- =============================================================================
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(s.line_revenue) AS monthly_revenue
    FROM sizwe_sales_orders o
    JOIN sizwe_sales_lines s 
        ON o.order_id = s.order_id
    GROUP BY 
        DATE_TRUNC('month', o.order_date)
)
SELECT 
    DATE_FORMAT(sales_month, 'yyyy-MM') AS month_year,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(monthly_revenue) OVER (ORDER BY sales_month), 0), 
        2
    ) AS pct_change_prev_month,
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY sales_month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS rolling_3m_avg
FROM monthly_sales
ORDER BY 
    sales_month;

-- Answer: Sizwe Coffee displays strong seasonality, with revenue building to a mid-year peak in June/July (reaching R45.13M) before declining through the spring. December is consistently the quietest month of the year (dipping to R29.87M in FY2024 and R32.61M in FY2025 due to holiday closures), followed by a sharp recovery starting in February (+12% growth).


-- =============================================================================
-- Task 8: Why Has the Margin Moved?
-- =============================================================================
WITH product_financials AS (
    SELECT 
        p.product_line,
        SUM(CASE WHEN o.order_date <= '2024-06-30' THEN s.line_revenue ELSE 0 END) AS fy24_revenue,
        SUM(CASE WHEN o.order_date <= '2024-06-30' THEN s.cogs ELSE 0 END) AS fy24_cogs,
        SUM(CASE WHEN o.order_date > '2024-06-30' THEN s.line_revenue ELSE 0 END) AS fy25_revenue,
        SUM(CASE WHEN o.order_date > '2024-06-30' THEN s.cogs ELSE 0 END) AS fy25_cogs
    FROM sizwe_sales_lines s
    JOIN sizwe_sales_orders o 
        ON s.order_id = o.order_id
    JOIN sizwe_products p 
        ON s.sku = p.sku
    GROUP BY 
        p.product_line
),
totals AS (
    SELECT 
        SUM(fy24_revenue) AS total_fy24_rev,
        SUM(fy25_revenue) AS total_fy25_rev
    FROM product_financials
)
SELECT 
    pf.product_line,
    ROUND(pf.fy24_revenue, 2) AS fy24_revenue,
    ROUND((pf.fy24_revenue - pf.fy24_cogs) * 100.0 / NULLIF(pf.fy24_revenue, 0), 2) AS fy24_gross_margin_pct,
    ROUND(pf.fy24_revenue * 100.0 / NULLIF(t.total_fy24_rev, 0), 2) AS fy24_share_of_revenue_pct,
    ROUND(pf.fy25_revenue, 2) AS fy25_revenue,
    ROUND((pf.fy25_revenue - pf.fy25_cogs) * 100.0 / NULLIF(pf.fy25_revenue, 0), 2) AS fy25_gross_margin_pct,
    ROUND(pf.fy25_revenue * 100.0 / NULLIF(t.total_fy25_rev, 0), 2) AS fy25_share_of_revenue_pct
FROM product_financials pf
CROSS JOIN totals t
ORDER BY 
    fy25_revenue DESC;

-- Answer: The overall gross margin contraction from 34.7% to 33.0% was caused by product mix dilution rather than declining product-level profitability. Margins within individual product lines remained virtually unchanged year-on-year; however, Bulk Commercial—the lowest-margin product line (19.91%)—grew rapidly from 25.02% of total revenue in FY2024 to 33.65% in FY2025 (R161.50M), diluting the company's weighted average margin.
