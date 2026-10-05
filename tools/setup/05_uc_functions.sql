-- Lab 5A — governed tools as Unity Catalog functions.
-- The function IS the tool. Its signature is the tool schema, its COMMENT is
-- the description the model reads, and UC GRANTs are the access control.

CREATE OR REPLACE FUNCTION agents_labs.retail.get_order_summary(
  order_ref STRING COMMENT 'Customer-facing order reference, e.g. ORD-1044'
)
RETURNS TABLE (
  order_id STRING, status STRING, item STRING, units INT,
  revenue DECIMAL(12,2), order_date DATE, region STRING, tier STRING
)
COMMENT 'Look up one order: fulfilment status, item, units, revenue, and the region and loyalty tier of the customer who placed it. Use this whenever a question refers to a specific order reference.'
RETURN
  SELECT o.order_id, o.status, o.item, o.units, o.revenue, o.order_date, c.region, c.tier
  FROM agents_labs.retail.orders o
  JOIN agents_labs.retail.customers c USING (customer_id)
  WHERE o.order_id = order_ref;

-- Deliberately scoped: revenue by region and month, no customer identifiers.
CREATE OR REPLACE FUNCTION agents_labs.retail.revenue_by_region(
  from_month STRING COMMENT 'Inclusive start month, format yyyy-MM, e.g. 2026-08'
)
RETURNS TABLE (region STRING, month STRING, revenue DECIMAL(12,2), orders INT)
COMMENT 'Aggregate revenue and order count by region and month, from the given month onward. Returns no customer-level detail.'
RETURN
  SELECT c.region,
         date_format(o.order_date, 'yyyy-MM') AS month,
         sum(o.revenue) AS revenue,
         CAST(count(*) AS INT) AS orders
  FROM agents_labs.retail.orders o
  JOIN agents_labs.retail.customers c USING (customer_id)
  WHERE date_format(o.order_date, 'yyyy-MM') >= from_month
  GROUP BY c.region, date_format(o.order_date, 'yyyy-MM');

SELECT * FROM agents_labs.retail.get_order_summary('ORD-1044');

SELECT * FROM agents_labs.retail.revenue_by_region('2026-08') ORDER BY region, month;
