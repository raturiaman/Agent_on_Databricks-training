TRUNCATE TABLE agents_labs.retail.customers;

INSERT INTO agents_labs.retail.customers VALUES
 ('CUST-001','Nordic Office Group','Nordics','premier',DATE'2023-02-14'),
 ('CUST-002','Fjord Interiors','Nordics','plus',DATE'2023-06-01'),
 ('CUST-003','Helsinki Works','Nordics','standard',DATE'2024-01-20'),
 ('CUST-004','Berlin Raumdesign','DACH','premier',DATE'2022-11-03'),
 ('CUST-005','Wien Buero','DACH','standard',DATE'2024-03-11'),
 ('CUST-006','Manchester Fitout','UK','plus',DATE'2023-09-27'),
 ('CUST-007','Thames Studios','UK','standard',DATE'2024-05-05'),
 ('CUST-008','Amsterdam Desk Co','Benelux','plus',DATE'2023-04-18');

TRUNCATE TABLE agents_labs.retail.orders;

-- August: Nordics healthy, carried by CUST-001 buying Seating.
INSERT INTO agents_labs.retail.orders VALUES
 ('ORD-1001','CUST-001',DATE'2026-08-04','Seating','ergonomic chair',40,220.00,8800.00,'delivered'),
 ('ORD-1002','CUST-001',DATE'2026-08-19','Seating','ergonomic chair',35,220.00,7700.00,'delivered'),
 ('ORD-1003','CUST-002',DATE'2026-08-07','Lighting','desk lamp',60,38.00,2280.00,'delivered'),
 ('ORD-1004','CUST-003',DATE'2026-08-22','Desks','standing desk',6,540.00,3240.00,'delivered'),
 ('ORD-1005','CUST-004',DATE'2026-08-06','Desks','standing desk',9,540.00,4860.00,'delivered'),
 ('ORD-1006','CUST-005',DATE'2026-08-15','Storage','filing cabinet',14,130.00,1820.00,'delivered'),
 ('ORD-1007','CUST-006',DATE'2026-08-11','Seating','task chair',25,145.00,3625.00,'delivered'),
 ('ORD-1008','CUST-007',DATE'2026-08-25','Lighting','floor lamp',18,72.00,1296.00,'delivered'),
 ('ORD-1009','CUST-008',DATE'2026-08-13','Storage','shelving unit',20,96.00,1920.00,'delivered');

-- September: Nordics drops. CUST-001 stops buying Seating entirely (churn),
-- and CUST-002's lamp price was discounted. Other regions are flat-to-up,
-- so the honest answer is "one customer, one product line, volume not price".
INSERT INTO agents_labs.retail.orders VALUES
 ('ORD-1042','CUST-003',DATE'2026-09-03','Lighting','desk lamp',1,38.00,38.00,'delivered'),
 ('ORD-1043','CUST-002',DATE'2026-09-09','Lighting','desk lamp',60,30.00,1800.00,'delivered'),
 ('ORD-1044','CUST-003',DATE'2026-09-18','Desks','standing desk',5,540.00,2700.00,'delivered'),
 ('ORD-1045','CUST-004',DATE'2026-09-05','Desks','standing desk',11,540.00,5940.00,'delivered'),
 ('ORD-1046','CUST-005',DATE'2026-09-16','Storage','filing cabinet',16,130.00,2080.00,'delivered'),
 ('ORD-1047','CUST-006',DATE'2026-09-10','Seating','task chair',28,145.00,4060.00,'delivered'),
 ('ORD-1048','CUST-007',DATE'2026-09-21','Lighting','floor lamp',20,72.00,1440.00,'delivered'),
 ('ORD-1049','CUST-008',DATE'2026-09-14','Storage','shelving unit',22,96.00,2112.00,'delivered'),
 ('ORD-2217','CUST-002',DATE'2026-09-24','Seating','office chair',1,140.00,140.00,'lost_in_transit'),
 ('ORD-2218','CUST-006',DATE'2026-09-26','Seating','task chair',2,145.00,290.00,'returned'),
 ('ORD-2219','CUST-007',DATE'2026-09-27','Desks','standing desk',1,540.00,540.00,'in_transit');

SELECT region, date_format(order_date,'yyyy-MM') AS month, sum(revenue) AS revenue
FROM agents_labs.retail.orders o JOIN agents_labs.retail.customers c USING (customer_id)
GROUP BY 1,2 ORDER BY 1,2;
