-- =====================================================
-- SINOTHANDO DATA INTEGRATION - RECONCILIATION CHECKS
-- Contributor: Sinothando Masiki
-- Purpose: Reconcile counts and totals across ETL layers
-- =====================================================

-- 1) High-level row-count reconciliation
SELECT 'orders_dw' AS table_name, COUNT(*) AS rows FROM grocery.orders_dw
UNION ALL
SELECT 'customer_activity', COUNT(*) FROM grocery.customer_activity
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM grocery.fact_sales
UNION ALL
SELECT 'customer_analytics', COUNT(*) FROM grocery.customer_analytics
ORDER BY table_name;

-- 2) Distinct business keys comparison across staging and fact
SELECT
    (SELECT COUNT(DISTINCT order_id) FROM grocery.orders_dw) AS staging_distinct_orders,
    (SELECT COUNT(*) FROM grocery.fact_sales) AS fact_rows;

-- 3) Revenue reconciliation: staging orders vs fact sales
SELECT
    ROUND((SELECT COALESCE(SUM(line_total), 0) FROM grocery.orders_dw)::numeric, 2) AS staging_revenue,
    ROUND((SELECT COALESCE(SUM(line_total), 0) FROM grocery.fact_sales)::numeric, 2) AS fact_revenue,
    ROUND(
        (SELECT COALESCE(SUM(line_total), 0) FROM grocery.orders_dw)::numeric
      - (SELECT COALESCE(SUM(line_total), 0) FROM grocery.fact_sales)::numeric
    , 2) AS revenue_difference;

-- 4) Quantity reconciliation: staging orders vs fact sales
SELECT
    COALESCE((SELECT SUM(quantity) FROM grocery.orders_dw), 0) AS staging_quantity,
    COALESCE((SELECT SUM(quantity) FROM grocery.fact_sales), 0) AS fact_quantity,
    COALESCE((SELECT SUM(quantity) FROM grocery.orders_dw), 0)
  - COALESCE((SELECT SUM(quantity) FROM grocery.fact_sales), 0) AS quantity_difference;

-- 5) Integrated table coverage against expected join grain
-- Expected matches are customer+product matches between orders and activity.
SELECT
    (SELECT COUNT(*)
     FROM grocery.orders_dw o
     JOIN grocery.customer_activity a
       ON o.customer_name = a.customer_name
      AND o.product = a.product) AS expected_join_rows,
    (SELECT COUNT(*) FROM grocery.customer_analytics) AS integrated_rows;

-- 6) Reconciliation by payment method (fact only)
SELECT
    dpm.payment_method,
    COUNT(*) AS fact_rows,
    ROUND(SUM(fs.line_total), 2) AS fact_revenue
FROM grocery.fact_sales fs
JOIN grocery.dim_payment dpm ON fs.payment_id = dpm.payment_id
GROUP BY dpm.payment_method
ORDER BY fact_revenue DESC;

-- 7) Reconciliation by activity type (integrated only)
SELECT
    activity,
    COUNT(*) AS integrated_rows,
    ROUND(SUM(line_total), 2) AS integrated_revenue
FROM grocery.customer_analytics
GROUP BY activity
ORDER BY integrated_rows DESC;
