# Lab 4B — Genie Inside an Agent

**Session:** 4 — Genie
**Duration:** ~45 minutes
**Where you work:** a Databricks notebook
**Compute:** Serverless

> **Verified on 2026-09-30.** Every output below is from a real run, including the one
> where the agent disagreed with the question.

---

## 1. Lab Overview & Objectives

In [Lab 4A](lab-4a-genie-space.md) you curated a Genie Agent and measured it: **0% → 100%**.

Here you make it **one tool among several**. The agent decides *when* a question needs
data, phrases its own question for Genie, and combines the result with the policy documents
from [Session 3](../session-3-grounding-and-rag/lab-3a-vector-search-index.md).

Along the way it settles something Session 3 left open: **when does curation get inherited
by a new consumer, and when does it not?**

**By the end of this lab you will be able to:**

1. Call Genie from code and get back the answer **and the SQL it ran**.
2. Show that Knowledge Store curation is inherited by a consumer that knows nothing about it.
3. Explain why the `audience` filter from Lab 3A is **not** inherited, and what that
   difference costs.
4. Recognise the relative-date trap, and where its fix belongs.

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Lab 4B - Genie Inside an Agent`** | Workspace → `Agents-on-Databricks-Labs` | The lab. **17 cells** — 9 explaining, 8 to run. |
| 2 | [`lab-4b-genie-inside-an-agent.ipynb`](../notebooks/lab-4b-genie-inside-an-agent.ipynb) | this repo, `notebooks/` | The same notebook with outputs saved. |

**To open it:** **Workspace** → `Agents-on-Databricks-Labs` →
**`Lab 4B - Genie Inside an Agent`**, attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

**Attach compute.** Use the selector in the notebook toolbar and pick **Serverless**.
Nothing in this lab needs a cluster.

![The notebook toolbar: Run all, and the Serverless compute selector](../artifacts/_shared/screenshots/notebook-toolbar-serverless.png)

---

## 3. Prerequisites

- [Lab 4A](lab-4a-genie-space.md) **completed and curated** — the instructions saved and the
  knowledge snippet accepted. Cell 3 tests for exactly those.
- [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md) — the policy index.
- Serverless compute.

---

## 4. What You're Building

```
                      agent (claude-sonnet-5)
                             │
              ┌──────────────┴──────────────┐
              │                             │
     query_business_data              search_policy
     → Genie Agent                    → support_chunks_idx
     "what happened"                  "what are the rules"
              │                             │
     carries the Lab 4A            carries NOTHING but the
     Knowledge Store               filter THIS caller passes
```

---

## 5. Step-by-Step Instructions

### Step 1 — Find the agent and ask it something (10 min)

Run **cell 0** (install), **cell 1** (find the agent by title), **cell 2** (ask it).

```
  agent    : Retail Customer Orders
  space_id : 01f1bc6b0a4f1c6d8269cc9c1ec2af08
```

> ⚠️ **This lab calls the Genie REST API directly, not `WorkspaceClient.genie`.**
>
> The first version used the SDK and failed on serverless with
> `AttributeError: 'WorkspaceClient' object has no attribute 'genie'` — while the identical
> code worked locally. **The SDK bundled with serverless compute is not always current.**
> REST does not have that problem, and it shows you what the SDK would be doing anyway.

Genie returns an answer **and the SQL it ran**. Keep the SQL — it is the audit trail, and
the thing to read when an answer surprises you.

---

### Step 2 — Is the curation inherited? (12 min)

**This is the cell to slow down for.** Run **cells 3 and 4**.

You fixed *"Who are our best customers?"* in Lab 4A by adding one SQL Expression and five
lines of General Instructions — **in the console**. This notebook is a completely different
consumer: different process, different client, no knowledge of what you typed.

Ask it the same question:

```sql
WITH customer_revenue AS (
  SELECT customers.customer_id, customers.name,
         SUM(orders.revenue) AS lifetime_revenue
  FROM agents_labs.retail.orders AS orders
  INNER JOIN agents_labs.retail.customers AS customers
    ON orders.customer_id = customers.customer_id
  GROUP BY customers.customer_id, customers.name
)
SELECT customer_id, name, lifetime_revenue
FROM customer_revenue
WHERE lifetime_revenue IS NOT NULL
ORDER BY lifetime_revenue DESC, customer_id ASC;
```

Cell 4 checks it against the three things you curated:

```
  check                                         observed  wanted
  uses SUM(orders.revenue)  [the snippet]           True    True   OK
  filters to 'delivered'    [fault 1]              False   False   OK
  groups by tier            [fault 2]              False   False   OK
```

**Three for three.** You wrote no curation in this notebook and inherited all of it.

> ⚠️ **Gotcha — my first version of this check reported a FAIL, and the check was wrong.**
>
> It also asserted *"returns exactly 5 rows"*. Genie returned **8**, and 8 is correct: the
> Lab 4A instruction says *"when the user asks for a top N, return exactly N rows"*, and
> *"Who are our best customers?"* does not ask for a top N. The `LIMIT 5` in the benchmark's
> ground truth was **your** choice of how many is enough, not something the question said.
>
> That makes three times in this course the **measuring instrument** has been the broken
> part — [Lab 6A](../session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md)'s
> judge, [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md)'s
> refusal detector, and now this. **Before you trust a check, feed it a case you have read
> yourself and confirm it agrees with you.**

---

### Step 3 — Wrap Genie as a tool (8 min)

Run **cells 5 and 6**.

Genie stops being the whole system and becomes one capability beside `search_policy`. The
tool **description** is what decides which one the agent reaches for:

| Tool | Description says | For |
|---|---|---|
| `query_business_data` | *"…anything requiring actual numbers from the warehouse. Do NOT use it for written policy."* | what happened |
| `search_policy` | *"…rules, not numbers."* | what the rules are |

> 💡 **That "Do NOT use it for written policy" clause is doing real work.** Without an
> explicit boundary, a capable model will happily ask Genie about returns policy and get a
> confidently wrong SQL query over tables that do not contain policy.

---

### Step 4 — Ask something that needs both (10 min)

Run **cell 7**:

> *"Nordics revenue dropped last month. What caused it, and is there anything in our
> policies that might explain a big customer going quiet?"*

```
  step 1: query_business_data('What caused the drop in Nordics revenue last month compared to the pre…')
  step 1: search_policy('customer inactivity churn returns delays that could cause a customer t…')
```

**Both tools, in parallel, with questions the agent wrote itself.** Neither is the wording
you typed — and reading them is the whole skill. A vague one here is the same failure as
[Lab 7A](../session-7-operations-and-multi-agent/lab-7a-multi-agent-supervisor.md)'s
starved worker.

**Then the agent did something better than answering:**

> **On the "drop" itself — the data doesn't actually show one**
>
> | Customer | Category | Prev month rev | Last month rev | Change | Returns |
> |---|---|---|---|---|---|
> | Nordic Office Group | Seating | €0.00 | €16,500.00 | **+16,500** | none |
> | Helsinki Works | Desks | €0.00 | €3,240.00 | **+3,240** | none |
>
> All three Nordics customer/category combinations that had any activity in either month
> actually **grew**… This means either the "drop" you're seeing is at a higher level of
> aggregation, or…

> 🚨 **Read that twice. The premise of the question was wrong, and the agent said so.**
>
> It did not invent a cause for a drop that its query did not find. Compare with
> [Lab 7A](../session-7-operations-and-multi-agent/lab-7a-multi-agent-supervisor.md), where
> a context-starved worker produced a fluent, well-cited answer to the wrong question.
> **Pushing back on the premise is the behaviour you want**, and it is worth pointing at
> explicitly, because most agent demos are built so it never has to happen.

**But why did it disagree?** Because *"last month"* is a **relative date**, and the dataset
has a fixed range ending in September 2026. Genie resolved "last month" against the real
calendar, not against `max(order_date)`, and landed on a window where Nordics grew from
zero.

Lab 4A Step 2 asked the same business question as *"from August to September 2026"* and got
the Nordics drop exactly right.

> 💡 **Where does that fix belong?** Not in the question — in the **Knowledge Store**, as an
> instruction like *"'last month' means the latest complete month present in
> orders.order_date, not the current calendar month."* Then every consumer inherits it,
> including this notebook. That is Step 2's lesson applied to a bug you found yourself.
>
> **Add it, re-run cell 7, and see whether the answer changes.**

---

### Step 5 — Where curation lives decides whether it travels (5 min)

Read **cell 8**. Two boundaries in this course, both enforced by "the right thing happens",
and only one survives a new consumer:

| | Lab 3A — the `audience` filter | Lab 4A — the Knowledge Store |
|---|---|---|
| Where it lives | the **calling code** (`filters={...}`) | the **Genie Agent** |
| A new consumer | [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md): Agent Bricks has no filter control and **discloses `DOC-006`** | this notebook: **inherits all three rules** |
| Why | every caller must remember | the agent carries it |

> 🚨 **The same lesson from both directions.** A rule enforced by the caller is a
> convention; a rule that lives with the resource is a control.
>
> When you design an agent system, ask of every rule: **if someone builds a second consumer
> tomorrow, do they inherit this or re-implement it?**

---

## 6. What You Learned

| You saw… | in Step | proof |
|---|---|---|
| The serverless SDK can lag; REST is portable | 1 gotcha | `no attribute 'genie'` |
| Genie returns the SQL, not just an answer | 1 | the full CTE in cell 3 |
| Knowledge Store curation is inherited by a new consumer | 2 | **3/3 checks OK**, nothing written here |
| A check can be wrong in your favour *and* against you | 2 gotcha | the bogus "exactly 5 rows" FAIL |
| Tool descriptions decide which source is used | 3 | *"Do NOT use it for written policy"* |
| The agent writes its own questions for each tool | 4 | neither matched the user's wording |
| **It rejected a false premise instead of confabulating** | 4 | *"the data doesn't actually show one"* |
| Relative dates are a trap against a fixed dataset | 4 | "last month" ≠ `max(order_date)` month |
| A caller-side rule is not inherited; an agent-side one is | 5 | 7B leaks, this notebook does not |

## 7. What You Hand In

Add the *"last month"* instruction to your Knowledge Store, re-run cell 7, and paste both
answers — before and after. If the answer did not change, say so: **an instruction that
does not move the output is worth knowing about**, and it is exactly what
[Lab 4A](lab-4a-genie-space.md)'s benchmarks exist to detect.

---

**Next:** [Lab 5A — Build a Governed Tool from a Unity Catalog Function](../session-5-tools-and-governance/lab-5a-governed-uc-function.md)
