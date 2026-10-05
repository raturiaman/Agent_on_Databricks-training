-- Shared dataset for Sessions 3-7 of the Agents on Databricks course.
-- Small on purpose: every lab must run inside a 2-hour session.

CREATE TABLE IF NOT EXISTS agents_labs.retail.customers (
  customer_id   STRING  COMMENT 'Surrogate key, e.g. CUST-001',
  name          STRING  COMMENT 'Customer full name',
  region        STRING  COMMENT 'Sales region: Nordics, DACH, UK, Benelux',
  tier          STRING  COMMENT 'Loyalty tier: standard, plus, premier',
  signup_date   DATE    COMMENT 'Date the customer account was created'
) COMMENT 'Retail customers. Used by Genie and by the governed UC function in Session 5.';

CREATE TABLE IF NOT EXISTS agents_labs.retail.orders (
  order_id      STRING  COMMENT 'Order reference shown to customers, e.g. ORD-1042',
  customer_id   STRING  COMMENT 'FK to customers.customer_id',
  order_date    DATE    COMMENT 'Date the order was placed',
  product_line  STRING  COMMENT 'Product line: Seating, Lighting, Desks, Storage',
  item          STRING  COMMENT 'Human readable item name',
  units         INT     COMMENT 'Number of units ordered',
  unit_price    DECIMAL(10,2) COMMENT 'Price per unit in GBP',
  revenue       DECIMAL(12,2) COMMENT 'units * unit_price, in GBP',
  status        STRING  COMMENT 'Fulfilment status: delivered, in_transit, lost_in_transit, returned, cancelled'
) COMMENT 'Retail orders. The structured half of the course: Genie queries this, and the Session 5 UC function reads it under least privilege.';

CREATE TABLE IF NOT EXISTS agents_labs.retail.support_docs (
  doc_id        STRING  COMMENT 'Stable document id',
  title         STRING  COMMENT 'Document title',
  category      STRING  COMMENT 'returns | delivery | warranty | billing',
  audience      STRING  COMMENT 'customer | agent_only  — used to prove metadata filtering in Lab 3A',
  body          STRING  COMMENT 'Full policy text, chunked in Lab 3A'
) COMMENT 'Support policy documents. The unstructured half: chunked, embedded and indexed in Lab 3A.';
