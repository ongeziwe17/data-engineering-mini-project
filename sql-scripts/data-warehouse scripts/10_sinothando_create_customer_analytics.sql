-- =====================================================
-- SINOTHANDO DATA INTEGRATION - CUSTOMER ANALYTICS
-- Contributor: Sinothando Masiki
-- =====================================================

-- Rebuild integrated table for rerun safety
TRUNCATE TABLE grocery.customer_analytics;

INSERT INTO grocery.customer_analytics(
    customer_name,
    product,
    category,
    activity,
    line_total,
    order_date,
    activity_timestamp,
    payment_method,
    order_status,
    device_type
)
SELECT DISTINCT
    dc.customer_name,
    dp.product_name,
    dp.category,
    da.activity_type,
    fs.line_total,
    dd.full_date AS order_date,
    ca.activity_timestamp,
    dpm.payment_method,
    fs.order_status,
    ca.device_type
FROM grocery.fact_sales fs
JOIN grocery.dim_customer dc ON fs.customer_id = dc.customer_id
JOIN grocery.dim_product dp ON fs.product_id = dp.product_id
JOIN grocery.dim_date dd ON fs.date_id = dd.date_id
JOIN grocery.dim_payment dpm ON fs.payment_id = dpm.payment_id
JOIN grocery.customer_activity ca
  ON dc.customer_name = ca.customer_name
 AND dp.product_name = ca.product
 AND COALESCE(dp.category, '') = COALESCE(ca.category, '')
JOIN grocery.dim_activity da ON ca.activity = da.activity_type;

-- Assignment-required integration join pattern (evidence)
SELECT
    o.customer_name,
    o.product,
    a.activity,
    o.line_total AS amount,
    o.order_date,
    a.activity_timestamp AS "timestamp"
FROM grocery.orders_dw o
JOIN grocery.customer_activity a
  ON o.customer_name = a.customer_name
 AND o.product = a.product
LIMIT 10;

-- Verification
SELECT COUNT(*) AS integrated_rows FROM grocery.customer_analytics;
SELECT * FROM grocery.customer_analytics LIMIT 10;
