-- =====================================================
-- SINOTHANDO DATA INTEGRATION - DATA QUALITY CHECKS
-- Contributor: Sinothando Masiki
-- Purpose: Validate staging and integrated data quality
-- =====================================================

-- 1) Required staging fields should not be null
SELECT 'orders_dw_null_required_fields' AS check_name, COUNT(*) AS issue_rows
FROM grocery.orders_dw
WHERE customer_name IS NULL
   OR product IS NULL
   OR order_date IS NULL
   OR quantity IS NULL
   OR unit_price IS NULL
   OR line_total IS NULL;

SELECT 'customer_activity_null_required_fields' AS check_name, COUNT(*) AS issue_rows
FROM grocery.customer_activity
WHERE customer_name IS NULL
   OR product IS NULL
   OR activity IS NULL
   OR activity_timestamp IS NULL;

-- 2) Numeric quality checks
SELECT 'orders_dw_negative_or_zero_values' AS check_name, COUNT(*) AS issue_rows
FROM grocery.orders_dw
WHERE quantity <= 0
   OR unit_price < 0
   OR line_total < 0;

-- 3) Validate line_total = quantity * unit_price (within rounding tolerance)
SELECT 'orders_dw_line_total_mismatch' AS check_name, COUNT(*) AS issue_rows
FROM grocery.orders_dw
WHERE ABS(line_total - ROUND((quantity * unit_price)::numeric, 2)) > 0.01;

-- 4) Duplicate transactional keys in staging (order_id expected unique)
SELECT 'orders_dw_duplicate_order_id' AS check_name, COUNT(*) AS duplicate_keys
FROM (
    SELECT order_id
    FROM grocery.orders_dw
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d;

-- 5) Unexpected activity types
SELECT 'customer_activity_invalid_activity_type' AS check_name, COUNT(*) AS issue_rows
FROM grocery.customer_activity
WHERE activity NOT IN ('Viewed', 'Added to Cart', 'Purchased');

-- 6) Missing category mappings for same product name
SELECT 'product_with_multiple_categories' AS check_name, COUNT(*) AS products_affected
FROM (
    SELECT product
    FROM grocery.orders_dw
    GROUP BY product
    HAVING COUNT(DISTINCT COALESCE(category, 'UNKNOWN')) > 1
) p;

-- 7) Orphaned activity records not linkable to orders by customer+product
SELECT 'activity_without_matching_order' AS check_name, COUNT(*) AS issue_rows
FROM grocery.customer_activity a
LEFT JOIN grocery.orders_dw o
  ON o.customer_name = a.customer_name
 AND o.product = a.product
WHERE o.order_id IS NULL;

-- 8) Integrated table null checks
SELECT 'customer_analytics_null_required_fields' AS check_name, COUNT(*) AS issue_rows
FROM grocery.customer_analytics
WHERE customer_name IS NULL
   OR product IS NULL
   OR activity IS NULL
   OR line_total IS NULL
   OR order_date IS NULL
   OR activity_timestamp IS NULL;
