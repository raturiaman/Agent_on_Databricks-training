# Lab 5A — The Function *Is* the Tool

**Session:** 5 — Tools and Governance
**Duration:** ~45 minutes
**Where you work:** a Databricks notebook
**Compute:** Serverless

> **Verified on 2026-09-30.** Every schema and grant below is from a real run.

---

## 1. Lab Overview & Objectives

Every tool so far has been three things kept in step by hand: a Python function, a JSON
schema you typed, and a permission check you remembered.

A **Unity Catalog function** collapses all three into one governed object. Its signature
becomes the schema, its `COMMENT` becomes the description the model reads, and its
`GRANT` becomes the access control.

**By the end of this lab you will be able to:**

1. Write a UC function whose `COMMENT` is written **for a model**, not for a colleague.
2. Read back the tool schema Databricks generated from it, and point at where each field
   came from.
3. Grant `EXECUTE` while withholding `SELECT`, and explain why that works.
4. Identify a service principal correctly when granting.

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Lab 5A - The Function Is the Tool`** | Workspace → `Agents-on-Databricks-Labs` | The lab. **12 cells** — 7 explaining, 5 to run. |
| 2 | [`lab-5a-function-is-the-tool.ipynb`](../notebooks/lab-5a-function-is-the-tool.ipynb) | this repo, `notebooks/` | The same notebook with outputs saved. |

**To open it:** **Workspace** → `Agents-on-Databricks-Labs` →
**`Lab 5A - The Function Is the Tool`**, attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

**Attach compute.** Use the selector in the notebook toolbar and pick **Serverless**.
Nothing in this lab needs a cluster.

![The notebook toolbar: Run all, and the Serverless compute selector](../artifacts/_shared/screenshots/notebook-toolbar-serverless.png)

---

## 3. Prerequisites

- `CREATE FUNCTION` and `SELECT` in `agents_labs.retail`.
- A service principal named `agents-labs-restricted` — your instructor creates it.
- Serverless compute.

---

## 4. What You're Building

```
  CREATE FUNCTION get_order_summary(
      order_ref STRING COMMENT 'e.g. ORD-1044'   ─┐
  )                                               │
  COMMENT 'Look up one order: … Use this whenever ─┼─► the tool schema
           a question refers to an order ref.'     │
  RETURN SELECT … FROM orders JOIN customers       │
                                                   │
  GRANT EXECUTE ON FUNCTION … TO <app-id>  ────────┴─► the access control
  (and NO grant on orders or customers)
```

---

## 5. Step-by-Step Instructions

### Step 1 — Write the COMMENT for a model (10 min)

Run **cell 1** (the setup) and **cell 2** (the `%sql` `CREATE FUNCTION`).

Read the `COMMENT` as if you were the model choosing a tool:

> *"Look up one order: fulfilment status, item, units, revenue, and the region and loyalty
> tier of the customer who placed it. **Use this whenever a question refers to a specific
> order reference.**"*

> 💡 **The second sentence is the one that earns its place.** The first says what the
> function returns; the second says **when to reach for it**. Most function comments are
> written for a colleague reading the catalog and stop after the first sentence — which
> leaves the model guessing.

The parameter has its own comment too, and it matters just as much:

```sql
order_ref STRING COMMENT 'Customer-facing order reference, e.g. ORD-1044'
```

---

### Step 2 — Confirm it is an ordinary SQL function (5 min)

Run **cell 3**. Before it is a tool, it is something an analyst can call:

```sql
SELECT * FROM agents_labs.retail.get_order_summary('ORD-1044')
```

---

### Step 3 — Read the schema Databricks generated (12 min)

Run **cell 4**. It asks the managed MCP server what tools exist.

```console
  tools discovered as admin@…: 2
    agents_labs__retail__get_order_summary
    agents_labs__retail__revenue_by_region

  the generated schema:
{
  "name": "agents_labs__retail__get_order_summary",
  "description": "Look up one order: fulfilment status, item, units, revenue, and the
                  region and loyalty tier of the customer who placed it. Use this
                  whenever a question refers to a specific order reference.",
  "inputSchema": {
    "type": "object",
    "required": ["order_ref"],
    "properties": {
      "order_ref": {
        "type": "string",
        "description": "Customer-facing order reference, e.g. ORD-1044"
      }
    }
  },
  "outputSchema": { … }
}
```

**You did not write a line of that.** Compare it with the hand-typed schemas in
[Lab 1B](../session-1-agent-architecture/lab-1b-minimal-agent.md) cell 4:

| In the tool schema | Came from |
|---|---|
| `description` | the function's **`COMMENT`** |
| `properties.order_ref.description` | the **parameter's** `COMMENT` |
| `required: ["order_ref"]` | the parameter having no default |
| `inputSchema.type` | the SQL types |

> 💡 **This is the practical argument for `COMMENT ON`.** An undocumented function makes a
> tool the model cannot choose correctly, and the fix is a comment, not a longer system
> prompt. The same comment also improves Catalog Explorer, Genie
> ([Lab 4A](../session-4-genie/lab-4a-genie-space.md)) and every analyst who reads the
> schema. **You write it once and four consumers get better.**

---

### Step 4 — Least privilege in two statements (12 min)

Run **cell 5**.

```console
  principals named 'agents-labs-restricted': 2
  granting to application_id: a43d91d6-5848-46f7-99d6-70737fd76451

  granted USE CATALOG, USE SCHEMA, EXECUTE to a43d91d6-…
  deliberately NOT granted: SELECT on orders, SELECT on customers

  FUNCTION get_order_summary    -> ['EXECUTE']
  TABLE    orders               -> no grants to the SP
```

**The agent can run the function and cannot read the tables it reads.** That is possible
because a UC function executes with **definer's rights** — as its owner, not its caller.

> ⚠️ **Grant to the application ID, not the display name.**
>
> The first version of this cell used `TO \`agents-labs-restricted\`` and failed:
>
> ```
> PRINCIPAL_DOES_NOT_EXIST: Could not find principal with name agents-labs-restricted
> ```
>
> Unity Catalog identifies a service principal by its **application ID** (a UUID). And
> note the first line of the output: this workspace has **two** principals with that
> display name — exactly the situation where granting by name would be ambiguous even if
> it worked.

---

## 6. What You Learned

| You saw… | in Step | proof |
|---|---|---|
| The `COMMENT` becomes the tool description | 3 | identical text in the schema |
| The parameter `COMMENT` becomes its description | 3 | `e.g. ORD-1044` |
| The schema is generated, not written | 3 | nothing typed in the notebook |
| One comment improves four consumers | 3 | agent, Catalog Explorer, Genie, analysts |
| `EXECUTE` without `SELECT` is coherent | 4 | definer's rights |
| Grants use the application ID | 4 gotcha | `PRINCIPAL_DOES_NOT_EXIST` |
| Display names are not unique | 4 | **2** principals share one name |

## 7. What You Hand In

Nothing. [Lab 5B](lab-5b-mcp-and-access-control.md) uses these grants directly.

---

**Next:** [Lab 5B — Two Identities, Two Tool Lists](lab-5b-mcp-and-access-control.md)
