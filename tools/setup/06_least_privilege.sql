-- Lab 5A/5B — least privilege for an agent's execution identity.
-- The service principal may EXECUTE the function. It may NOT read the tables
-- the function reads. That gap is the entire point.

GRANT USE CATALOG ON CATALOG agents_labs TO `82052317-4dfb-44dd-9719-2ef5368618bb`;
GRANT USE SCHEMA ON SCHEMA agents_labs.retail TO `82052317-4dfb-44dd-9719-2ef5368618bb`;
GRANT EXECUTE ON FUNCTION agents_labs.retail.get_order_summary TO `82052317-4dfb-44dd-9719-2ef5368618bb`;

-- deliberately NOT granted:
--   SELECT ON TABLE agents_labs.retail.orders
--   SELECT ON TABLE agents_labs.retail.customers
--   EXECUTE ON FUNCTION agents_labs.retail.revenue_by_region

SHOW GRANTS ON FUNCTION agents_labs.retail.get_order_summary;
