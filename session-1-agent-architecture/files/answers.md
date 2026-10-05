# Worked Answers

> ⚠️ **Do not open this until Part 1 of [`worksheet.md`](worksheet.md) is filled in.**
> The value of this exercise is in the disagreement, and you only get that once.

**Two are workflows. Two are agents.**

---

## A — Workflow

The steps are known: for each PDF, extract three fields, write a row. Nothing about
invoice #2,817 changes what you do for invoice #2,818.

The varying layouts are handled by the **extraction model** — a document model with a
fixed output schema — not by a decision loop.

> **Why people get this wrong:** "the PDFs vary" *feels* like it needs reasoning. It
> needs a good extractor. Wrapping 4,000 invoices in an agent multiplies your token
> cost by the number of loop iterations, and gives you 4,000 chances to do something
> unexpected.

**The tell:** it is a `for` loop over independent items, and the loop body is identical
every time.

---

## B — Agent

The path branches on **what the customer wants**. A how-to question and a refund
request go down different routes, and the number of steps is not known in advance.

| Component | Answer |
|---|---|
| **Instructions** | Resolve the customer's issue. Never refund above £50 without human approval. Never promise a delivery date you have not looked up. |
| **Model** | Something reliable at picking tools. This is what [Lab 1B](../lab-1b-minimal-agent.md) builds. |
| **Tools** | `lookup_account(customer_id)`, `get_order_status(order_id)`, `search_kb(query)`, `issue_refund(order_id, amount)` — the last one gated. |
| **State** | The conversation so far, the customer identity once resolved, and which tools have already been tried so it does not loop. |

---

## C — Workflow

Same six KPIs, same format, same source table, every quarter. This is **one prompt**
with the metrics interpolated into it.

If the commentary is poor, the fix is a better prompt or a few examples — not a
decision loop.

**The tell:** you could write the steps on a napkin before seeing the data, and you
would be right every quarter.

---

## D — Agent, and it is the interesting one

Each query's result decides the next query. *"Which country moved?"* cannot be known
until the regional breakdown has run.

The stopping condition is **"I can explain the movement"** — not *"I have run five
queries"*.

| Component | Answer |
|---|---|
| **Instructions** | Explain the movement, showing the numbers you relied on. Say so if the data does not support a conclusion. |
| **Model** | One that can write SQL and judge when it has enough. |
| **Tools** | A governed query capability over the warehouse. **This is exactly what Genie is** — [Session 4](../../session-4-genie/lab-4a-genie-space.md) builds it. |
| **State** | Findings so far, so step four knows what step two established. |

---

## The pattern worth keeping

**B and D are agents for different reasons.**

- **B** branches on the *kind* of request.
- **D** branches on the *result of the previous step*.

**A and C are workflows even though both use a model** — because in both, you can write
the step sequence down before you see the data.

| | Branches on | Steps known up front? | Verdict |
|---|---|---|---|
| A | nothing | yes | workflow |
| B | kind of request | no | **agent** |
| C | nothing | yes | workflow |
| D | previous result | no | **agent** |
