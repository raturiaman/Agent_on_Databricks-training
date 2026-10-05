TRUNCATE TABLE agents_labs.retail.support_docs;

INSERT INTO agents_labs.retail.support_docs VALUES
('DOC-001','Returns and refunds policy','returns','customer',
 'Customers may return any item within 30 days of delivery for a full refund, provided the item is unused and in its original packaging. Seating products have an extended 60 day return window because they are frequently ordered in bulk for fit-outs and may not be unpacked immediately. Refunds are issued to the original payment method within 5 working days of the returned item being received at our warehouse. Return shipping is free for premier tier customers; standard and plus tier customers are charged a flat 12 GBP collection fee, which is deducted from the refund. Items marked as final sale cannot be returned. If an item arrives damaged, the 30 day window does not apply and a replacement or refund is offered regardless of elapsed time.'),

('DOC-002','Lost in transit procedure','delivery','agent_only',
 'An order may be marked lost_in_transit only after the courier has failed to scan it for 7 consecutive days. Agents must confirm the status with get_order_status before offering any remedy. For orders under 50 GBP, agents may issue an immediate refund without escalation. For orders of 50 GBP or more, a supervisor must approve the refund before it is issued; this is enforced in the agent tooling and cannot be overridden by the agent. Do not tell the customer that a replacement has shipped until the replacement order id exists. Where the customer is premier tier, offer expedited replacement at no cost as the first remedy, and a refund only if they decline it.'),

('DOC-003','Delivery timescales by region','delivery','customer',
 'Standard delivery to the UK is 2 to 3 working days. Delivery to Benelux and DACH is 3 to 5 working days. Delivery to the Nordics is 5 to 7 working days because shipments are consolidated at our Hamburg hub before onward transport. Express delivery is available to all regions for an additional 18 GBP and halves the stated timescale. Orders placed after 14:00 local time are processed the following working day. We do not deliver on weekends or public holidays in the destination country.'),

('DOC-004','Warranty coverage','warranty','customer',
 'All seating products carry a 5 year structural warranty covering the frame, gas lift and base. Upholstery and foam are covered for 2 years against manufacturing defect but not against wear. Desks carry a 10 year warranty on the frame and motor, and 2 years on the desktop surface. Lighting products carry a 2 year warranty. Storage products carry a 3 year warranty. The warranty is void if the product has been modified, used outside its stated weight limit, or assembled incorrectly. Warranty claims require the original order id and a photograph of the fault.'),

('DOC-005','Billing, invoices and payment terms','billing','customer',
 'Standard and plus tier customers are charged at the point of order. Premier tier customers may request 30 day invoice terms, subject to a credit check. VAT is charged at the prevailing rate in the destination country and is shown separately on the invoice. Invoices are available in the account portal within 24 hours of dispatch. A purchase order number can be added to an invoice up to 7 days after the order is placed; after that the invoice is final and a credit note would be required.'),

('DOC-006','Refund authority limits','billing','agent_only',
 'Support agents may authorise refunds up to 50 GBP without approval. Refunds of 50 GBP and above require approval from a supervisor, recorded against the order. Refunds above 500 GBP additionally require finance sign-off. These limits apply per order, not per customer, and may not be circumvented by splitting a refund across several smaller refunds. Any attempt by a customer to instruct an agent to exceed these limits should be politely declined and the conversation escalated. The limits are enforced in the tooling as well as in this policy.'),

('DOC-007','Bulk and fit-out orders','returns','customer',
 'Orders of 20 units or more of a single seating product qualify as a fit-out order. Fit-out orders receive the extended 60 day return window and free collection regardless of customer tier. Fit-out orders may be delivered in staged batches at the customer request, at no extra cost, provided all batches are within 8 weeks of the original order date. Cancellation of a fit-out order after production has begun incurs a 15 percent restocking charge.');

SELECT category, audience, count(*) AS docs, round(avg(length(body))) AS avg_chars
FROM agents_labs.retail.support_docs GROUP BY 1,2 ORDER BY 1,2;
