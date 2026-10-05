# Four Scenarios

**Read this file. Do not write in it.**

Each scenario is a real request from a business. For each one you decide: does it need
an **agent**, or is a **workflow** enough?

Write your answers in [`worksheet.md`](worksheet.md).

---

## Scenario A — Nightly invoice summaries

**Who's asking:** Finance.

> Every night we receive about **4,000 invoices**. For each one, pull out the vendor
> name, the total, and the due date, and write them to a table. The invoice PDFs come
> from hundreds of different suppliers, so the layouts vary a lot. We need the table
> ready by 6am.

**What you know up front:** the three fields, the output table, the deadline.
**What varies:** the layout of each PDF.

---

## Scenario B — Support ticket triage and resolution

**Who's asking:** Customer Support.

> A customer writes in. The system has to work out what they want, look up their
> account, check their order status if that's relevant, search the knowledge base if
> it's a how-to question, issue a refund if our policy allows it, and hand over to a
> human if it can't sort it out. We get about **300 tickets a day**.

**What you know up front:** the tools available, the refund policy.
**What varies:** what the customer wants, and therefore which tools get used, and in
what order.

---

## Scenario C — Quarterly board pack commentary

**Who's asking:** the CFO's office.

> Take the finalised quarterly metrics table and write two paragraphs explaining how
> each of our **six KPIs** moved against last quarter. Same six KPIs every time. Same
> format every time.

**What you know up front:** the six KPIs, the source table, the output format.
**What varies:** the numbers.

---

## Scenario D — "Why did revenue drop in the Nordics last month?"

**Who's asking:** an analyst, in chat.

> Answering this properly means querying revenue by region, noticing which country
> moved, breaking that country down by product line, working out whether it was volume
> or price, and possibly checking whether a large customer stopped ordering.

**What you know up front:** that you have a governed warehouse to query.
**What varies:** *which* of those steps are needed — and you cannot know until you've
run the first one.

> This is not a hypothetical. The data in this course contains a real Nordics revenue
> drop, and in [Lab 4A](../../session-4-genie/lab-4a-genie-space.md) you will watch
> an agent find the cause on its own.
