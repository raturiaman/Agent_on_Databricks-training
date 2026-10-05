# Lab 7A — A Supervisor Delegating to Two Workers

**Session:** 7 — Operations and Multi-Agent Systems
**Duration:** ~50 minutes
**Where you work:** a Databricks notebook
**Compute:** Serverless

> **Verified on 2026-09-30.** Every transcript below is from a real run.

---

## 1. Lab Overview & Objectives

Every agent so far has been one loop with several tools. This one splits into a
**supervisor** that owns no tools at all and two **workers** that each own one capability.

**By the end of this lab you will be able to:**

1. Split an agent into a supervisor and specialist workers, and say what the split buys.
2. Explain why a worker must receive a **standalone** task — and what breaks when it does
   not, which is **not** what most people expect.
3. Read a multi-agent run from its MLflow span tree.
4. State the cost: latency multiplies with the number of hops.

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Lab 7A - Supervisor and Workers`** | Workspace → `Agents-on-Databricks-Labs` | The lab. **17 cells** — 10 explaining, 7 to run. |
| 2 | [`lab-7a-supervisor-and-workers.ipynb`](../notebooks/lab-7a-supervisor-and-workers.ipynb) | this repo, `notebooks/` | The same notebook with outputs saved. |

**To open it:** **Workspace** → `Agents-on-Databricks-Labs` →
**`Lab 7A - Supervisor and Workers`**, attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

**Attach compute.** Use the selector in the notebook toolbar and pick **Serverless**.

![The notebook toolbar: Run all, and the Serverless compute selector](../artifacts/_shared/screenshots/notebook-toolbar-serverless.png)

> ⚠️ **Each supervisor run is 60–90 seconds.** Genie is slow, and every delegation adds a
> full model round-trip on top of the worker's own call.

---

## 3. Prerequisites

- [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md) — the index.
- [Lab 4A](../session-4-genie/lab-4a-genie-space.md) — a Genie Agent titled
  `Retail Customer Orders`.

---

## 4. What You're Building

```
  user request
        │
        ▼
  supervisor  — no tools of its own, only delegate(worker, task)
        │
    ┌───┴────────────────┐
    ▼                    ▼
  analytics            policy
  Genie · governed     vector index · documents
  tables               NO data access
  NO policy access
```

The supervisor cannot answer anything itself. That constraint is the design: it forces
every fact in the final answer to come from a worker accountable for it.

---

## 5. Step-by-Step Instructions

### Step 1 — Build the two workers (10 min)

Run **cells 0–2**.

| Worker | Capability | Deliberately lacks |
|---|---|---|
| `analytics_worker` | Genie over `agents_labs.retail` | any policy access |
| `policy_worker` | vector search, `audience: customer` | any order or customer data |

Both are decorated `@mlflow.trace(span_type="AGENT")`. That decorator is what makes the
hand-offs visible in Step 4.

> 💡 **The tool description is the routing logic.** There is no router model and no
> classifier — the supervisor picks a worker by reading the `delegate` description. An
> imprecise description produces mis-routing, and the fix is editing prose, not code.

---

### Step 2 — Watch it re-delegate (12 min)

Run **cells 3–4**.

> *"Order ORD-1007 — look up what was ordered and by whom, then tell me whether that
> customer would pay a return shipping fee if they sent it back."*

```console
  step 1: delegate -> analytics
           task: Look up order ORD-1007. Provide: the items ordered, the customer…
  step 1: delegate -> policy
           task: What is the company policy on return shipping fees? Specifically…
  step 2: delegate -> analytics
           task: For order ORD-1007 (customer CUST-006, item: task chair), what is
                 the quantity of task chair…
  step 3: supervisor combines the findings
```

**Read the third delegation — it is the whole point.**

The supervisor went **back** to analytics. It did not plan three steps up front:

1. Ask analytics who placed ORD-1007 → *Manchester Fitout, CUST-006, plus tier, task chair*.
2. Ask policy about return fees → £12 flat fee, **but DOC-007 gives free collection on
   20+ units of one seating product**.
3. It now knows a fact it did not have in step 1 changes the answer, and does not know the
   quantity. So it re-delegates → **25 units**.

The answer inverts from *"£12 fee"* to *"free collection"*.

> 💡 A single-agent version with both tools would likely have stopped at the £12 answer.
> The supervisor pattern did not make the model smarter; it made the **gap between
> findings** explicit enough to act on.

> ⚠️ **This is emergent, not guaranteed.** Re-run it and you may get two delegations and
> the £12 answer. Nothing in the code forces the re-delegation. If a correct answer matters
> here, **encode the dependency** — check quantity before quoting a fee — rather than
> hoping the supervisor rediscovers it. That is the [Lab 7B](lab-7b-rollout-and-agent-bricks.md)
> argument for constrained flows over free delegation.

---

### Step 3 — Starve a worker on purpose (12 min)

Run **cell 5**. The same worker gets two phrasings of one question.

| | task |
|---|---|
| **Context-dependent** | `Would that customer pay a return shipping fee?` |
| **Standalone** | `A 'plus' tier customer is returning 25 units of a single seating product. Would they pay a return shipping fee?` |

**What did *not* happen:** it did not crash, and it did not say *"I don't know who you
mean."*

```console
  CONTEXT-DEPENDENT
  Based on the excerpts, whether a return shipping fee applies depends on the
  customer's tier (DOC-001):
  - Premier tier customers: Return shipping is free.
  - Standard and Plus tier customers: A flat 12 GBP collection fee is charged…
  cited: ['DOC-001', 'DOC-005', 'DOC-001']

  STANDALONE
  No, they would not pay a return shipping fee. According to DOC-007, an order of
  20 units or more of a single seating product qualifies as a "fit-out order"…
  cited: ['DOC-001', 'DOC-007', 'DOC-005']
```

**Compare the `cited` lines. The vague task never retrieved DOC-007.**

The task string *is* the retrieval query. *"Would that customer pay a return shipping fee?"*
contains no signal for *25 units* or *seating*, so the fit-out exception was never in the
candidate set — the worker could not have applied it. It then produced a fluent,
correctly-cited, tier-accurate answer that is **the wrong answer for this customer**.

> 🚨 **This is the failure mode that survives review.** A starved worker does not refuse.
> It answers the general question instead of the specific one, cites real documents, and
> hands back something a reviewer will accept. In a multi-agent system the supervisor *is*
> that reviewer, and it has no way to know a document it never saw exists.
>
> **When a worker's task doubles as a retrieval query, the supervisor's phrasing is a
> retrieval-quality problem, not a prose problem.**

---

### Step 4 — Read the span tree (8 min)

Run **cell 6**.

```console
  trace_location : UnityCatalog(catalog_name='agents_labs', schema_name='retail', …)
  traces         : 5

  run                [AGENT]
    analytics_worker   [AGENT]   task: Look up order ORD-1007. Provide: the items…
    policy_worker      [AGENT]   task: What is the company policy on return shipping…
    analytics_worker   [AGENT]   task: For order ORD-1007 (customer CUST-006, item…
```

Three things this gives you that stdout does not:

1. **The task strings are stored.** Step 3 proved the task string determines retrieval
   quality. This is where you audit it after the fact.
2. **The hop count and duration** — roughly six model calls for one user question.
3. **It is a Delta table.** *"How often does the supervisor re-delegate to the same
   worker?"* is a SQL query, not a log-grep.

> 💡 **Gotcha worth knowing.** `span.inputs` comes back as a **dict** for some spans and as
> the **JSON text** of one for others. The reader handles both; the first version crashed
> with `AttributeError: 'str' object has no attribute 'get'`.

---

### Step 5 — Weigh it honestly (8 min)

| | Single agent, both tools | Supervisor + workers |
|---|---|---|
| Latency | one loop, ~25s | **~60s**, 3 hops |
| Model calls | ~3 | ~6 |
| Accountability | one context holds everything | each fact traces to a named worker |
| Governance | one identity needs every grant | each worker can be its own principal |
| Prompt size | grows with every tool | each worker's stays small |
| Failure mode | tool confusion | **silent context starvation** |

> 💡 **The pattern earns its cost when workers need different privileges.** An analytics
> worker touching governed tables under a principal with no business reading internal
> policy is a real separation, enforced by Unity Catalog rather than by a prompt —
> [Lab 5B](../session-5-tools-and-governance/lab-5b-mcp-and-access-control.md) showed each
> worker can be a distinct service principal whose MCP tool list is filtered by its grants.
>
> It is **not** worth 2.5× the latency purely to tidy up your prompts.

---

## 6. What You Learned

| You saw… | in Step | proof |
|---|---|---|
| Routing is a tool description, not a classifier | 1 | one `delegate` tool |
| A supervisor can re-delegate after learning a fact | 2 | step 2 returns to analytics |
| The correct answer inverted the naive one | 2 | £12 → free, via DOC-007 |
| The re-delegation is emergent, not guaranteed | 2 | nothing in code forces it |
| A starved worker answers confidently, not by refusing | 3 | fluent, cited, wrong-for-this-case |
| The task string **is** the retrieval query | 3 | `DOC-007` absent from `cited` |
| Span trees record every task string | 4 | task text per worker |
| Traces land in a UC Delta table | 4 | `trace_location` |
| The pattern costs ~2.5× latency | 5 | ~60s vs ~25s |

## 7. What You Hand In

Run cell 4 **three times** and record the number of delegations each time. If it varies,
that is the finding — write one sentence on what you would do about it in a system where
the answer has to be right every time.

## 8. Evidence

- [`artifacts/lab-7a/evidence/01-dependent-chain.txt`](../artifacts/lab-7a/evidence/01-dependent-chain.txt) — a three-delegation run in full.
- [`artifacts/lab-7a/evidence/02-span-tree.txt`](../artifacts/lab-7a/evidence/02-span-tree.txt) — span tree and UC trace location.
- [`artifacts/lab-7a/evidence/03-worker-isolation.txt`](../artifacts/lab-7a/evidence/03-worker-isolation.txt) — both phrasings, both citation sets.

Source: [`notebooks/lab-7a-supervisor-and-workers.ipynb`](../notebooks/lab-7a-supervisor-and-workers.ipynb).

---

**Next:** [Lab 7B — Canaries, Safe Rollback, and Agent Bricks](lab-7b-rollout-and-agent-bricks.md)
