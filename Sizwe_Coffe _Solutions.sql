

-- Question 1: Every product on the price list
SELECT 
    sku, 
    product_name, 
    product_line, 
    list_price
FROM sizwe_products
ORDER BY 
    product_line ASC, 
    list_price ASC;

-- Question 2: One product line only
SELECT 
    sku, 
    product_name, 
    pack_size, 
    list_price
FROM sizwe_products
WHERE product_line = 'Single Origin'
ORDER BY list_price DESC;

-- Question 3: Wholesale customers in two provinces
SELECT 
    customer_id, 
    trading_name, 
    province, 
    segment, 
    credit_limit
FROM sizwe_customers
WHERE channel = 'Wholesale'
  AND province IN ('Gauteng', 'Western Cape')
ORDER BY 
    province ASC, 
    trading_name ASC;

-- Question 4: The ten largest credit limits
SELECT 
    customer_id, 
    trading_name, 
    province, 
    credit_limit
FROM sizwe_customers
ORDER BY credit_limit DESC
LIMIT 10;

-- Question 5: Orders in a single month
SELECT 
    order_id, 
    customer_id, 
    order_date, 
    delivery_date, 
    channel
FROM sizwe_sales_orders
WHERE order_date >= '2025-06-01' 
  AND order_date <= '2025-06-30'
ORDER BY order_date ASC;



-- Question 6: Customers per province
SELECT 
    province, 
    COUNT(customer_id) AS total_customers
FROM sizwe_customers
GROUP BY province
ORDER BY total_customers DESC;

-- Question 7: Performance by SKU
SELECT 
    sku, 
    SUM(units) AS total_units, 
    ROUND(SUM(line_revenue), 2) AS total_revenue, 
    ROUND(AVG(discount_pct), 4) AS avg_discount
FROM sizwe_sales_lines
GROUP BY sku
ORDER BY total_revenue DESC;

-- Question 8: Only the SKUs that matter
SELECT 
    sku, 
    COUNT(order_id) AS order_line_count,
    SUM(units) AS total_units, 
    ROUND(SUM(line_revenue), 2) AS total_revenue, 
    ROUND(AVG(discount_pct), 4) AS avg_discount
FROM sizwe_sales_lines
GROUP BY sku
HAVING SUM(line_revenue) > 50000000
ORDER BY total_revenue DESC;

-- Question 9: Invoicing by month (FY2025: July 2024 to June 2025)
SELECT 
    DATE_TRUNC('month', invoice_date) AS invoice_month, 
    COUNT(*) AS invoice_count, 
    ROUND(SUM(invoice_amount), 2) AS total_value
FROM sizwe_ar_ledger
WHERE invoice_date >= '2024-07-01' 
  AND invoice_date <= '2025-06-30'
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY invoice_month ASC;



-- Question 10: Orders with the customer name
SELECT 
    o.order_id, 
    o.order_date, 
    c.trading_name, 
    c.province, 
    o.channel
FROM sizwe_sales_orders o
INNER JOIN sizwe_customers c 
    ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 20;

-- Question 11: Revenue by product line
SELECT 
    p.product_line, 
    SUM(sl.units) AS total_units, 
    ROUND(SUM(sl.line_revenue), 2) AS total_revenue
FROM sizwe_sales_lines sl
INNER JOIN sizwe_products p 
    ON sl.sku = p.sku
GROUP BY p.product_line
ORDER BY total_revenue DESC;

-- Question 12: Who has never had promotional support?
SELECT 
    c.customer_id, 
    c.trading_name, 
    COUNT(tp.customer_id) AS promotion_count
FROM sizwe_customers c
LEFT JOIN sizwe_trade_promotions tp 
    ON c.customer_id = tp.customer_id
GROUP BY 
    c.customer_id, 
    c.trading_name
ORDER BY 
    promotion_count ASC, 
    c.trading_name ASC
LIMIT 20;

-- Question 13: Revenue by province
SELECT 
    c.province, 
    COUNT(DISTINCT so.order_id) AS total_orders, 
    ROUND(SUM(sl.line_revenue), 2) AS total_revenue
FROM sizwe_customers c
INNER JOIN sizwe_sales_orders so 
    ON c.customer_id = so.customer_id
INNER JOIN sizwe_sales_lines sl 
    ON so.order_id = sl.order_id
GROUP BY c.province
ORDER BY total_revenue DESC;


-- Question 14: Customers above the average credit limit
SELECT 
    customer_id, 
    trading_name, 
    province, 
    credit_limit
FROM sizwe_customers
WHERE credit_limit > (
    SELECT AVG(credit_limit) 
    FROM sizwe_customers
)
ORDER BY credit_limit DESC;

-- Question 15: The ten biggest customers
WITH customer_revenue AS (
    SELECT 
        so.customer_id, 
        SUM(sl.line_revenue) AS total_revenue
    FROM sizwe_sales_orders so
    INNER JOIN sizwe_sales_lines sl 
        ON so.order_id = sl.order_id
    GROUP BY so.customer_id
)
SELECT 
    c.customer_id, 
    c.trading_name, 
    c.province, 
    c.channel, 
    ROUND(cr.total_revenue, 2) AS total_revenue
FROM customer_revenue cr
INNER JOIN sizwe_customers c 
    ON cr.customer_id = c.customer_id
ORDER BY cr.total_revenue DESC
LIMIT 10;

-- Question 16: Customers no rep has ever visited
SELECT 
    customer_id, 
    trading_name, 
    channel, 
    province
FROM sizwe_customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM sizwe_rep_visits 
    WHERE customer_id IS NOT NULL
)
ORDER BY trading_name ASC;



-- Question 17: Ranking customers
WITH customer_revenue AS (
    SELECT 
        c.trading_name, 
        c.province, 
        ROUND(SUM(sl.line_revenue), 2) AS revenue,
        RANK() OVER (ORDER BY SUM(sl.line_revenue) DESC) AS rank_position
    FROM sizwe_customers c
    INNER JOIN sizwe_sales_orders so 
        ON c.customer_id = so.customer_id
    INNER JOIN sizwe_sales_lines sl 
        ON so.order_id = sl.order_id
    GROUP BY c.customer_id, c.trading_name, c.province
)
SELECT 
    trading_name, 
    province, 
    revenue, 
    rank_position
FROM customer_revenue
WHERE rank_position <= 15
ORDER BY rank_position ASC;

-- Question 18: The top three in each province
WITH province_ranks AS (
    SELECT 
        c.province, 
        c.trading_name, 
        ROUND(SUM(sl.line_revenue), 2) AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY c.province 
            ORDER BY SUM(sl.line_revenue) DESC
        ) AS province_position
    FROM sizwe_customers c
    INNER JOIN sizwe_sales_orders so 
        ON c.customer_id = so.customer_id
    INNER JOIN sizwe_sales_lines sl 
        ON so.order_id = sl.order_id
    GROUP BY c.customer_id, c.province, c.trading_name
)
SELECT 
    province, 
    trading_name, 
    revenue, 
    province_position
FROM province_ranks
WHERE province_position <= 3
ORDER BY province ASC, province_position ASC;

-- Question 19: Month-on-month movement
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', so.order_date) AS month,
        SUM(sl.line_revenue) AS total_revenue
    FROM sizwe_sales_orders so
    INNER JOIN sizwe_sales_lines sl 
        ON so.order_id = sl.order_id
    GROUP BY DATE_TRUNC('month', so.order_date)
)
SELECT 
    month,
    ROUND(total_revenue, 2) AS current_month_revenue,
    ROUND(LAG(total_revenue, 1) OVER (ORDER BY month ASC), 2) AS previous_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY month ASC)) 
        / LAG(total_revenue, 1) OVER (ORDER BY month ASC) * 100, 
        2
    ) AS pct_change
FROM monthly_sales
ORDER BY month ASC;



-- Question 20: One list of everyone Sizwe trades with
SELECT 
    'Customer' AS entity_type, 
    CAST(customer_id AS STRING) AS entity_id, 
    trading_name AS entity_name, 
    province AS detail
FROM sizwe_customers

UNION ALL

SELECT 
    'Vendor' AS entity_type, 
    CAST(vendor_id AS STRING) AS entity_id, 
    vendor_name AS entity_name, 
    vendor_type AS detail
FROM sizwe_vendors

ORDER BY entity_type ASC, entity_name ASC;
