# Lab 5B — Two Identities, Two Tool Lists

**Session:** 5 — Tools and Governance
**Duration:** ~45 minutes
**Where you work:** a Databricks notebook
**Compute:** Serverless

> **Verified on 2026-09-30.** Every tool list and error message below is from a real run.

---

## 1. Lab Overview & Objectives

[Lab 5A](lab-5a-governed-uc-function.md) granted the agent's service principal `EXECUTE`
on **one** function and nothing else.

This lab asks the managed MCP server the same question as two different identities and
compares the answers. The result is the most important governance idea in the course:
**the tool list itself is filtered by your grants.**

**By the end of this lab you will be able to:**

1. Call a Databricks managed MCP server with `tools/list` and `tools/call`.
2. Show that two identities asking the same server get **different tool lists**.
3. Explain why the ungranted call fails with *"not found"* rather than *"denied"* — and
   why that wording is the point.
4. Argue for filtered discovery over a permission check at call time.

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Lab 5B - Two Identities`** | Workspace → `Agents-on-Databricks-Labs` | The lab. **13 cells** — 8 explaining, 5 to run. |
| 2 | [`lab-5b-two-identities.ipynb`](../notebooks/lab-5b-two-identities.ipynb) | this repo, `notebooks/` | The same notebook with outputs saved. |

**To open it:** **Workspace** → `Agents-on-Databricks-Labs` → **`Lab 5B - Two Identities`**,
attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

**Attach compute.** Use the selector in the notebook toolbar and pick **Serverless**.
Nothing in this lab needs a cluster.

![The notebook toolbar: Run all, and the Serverless compute selector](../artifacts/_shared/screenshots/notebook-toolbar-serverless.png)

---

## 3. Prerequisites

- [Lab 5A](lab-5a-governed-uc-function.md) — the function and the grants.
- A **secret scope** called `agents-labs` holding the restricted principal's OAuth
  credentials. Your instructor creates it:

  ```bash
  databricks secrets create-scope agents-labs
  databricks secrets put-secret agents-labs restricted_client_id
  databricks secrets put-secret agents-labs restricted_client_secret
  ```

---

## 4. What You're Building

```
              /api/2.0/mcp/functions/agents_labs/retail
                              │
              ┌───────────────┴───────────────┐
        your token                      SP token
              │                               │
        tools/list                      tools/list
              │                               │
   get_order_summary                 get_order_summary
   revenue_by_region                        ⌀
              │                               │
        both callable            revenue_by_region → "not found"
```

---

## 5. Step-by-Step Instructions

### Step 1 — Discover as yourself (8 min)

Run **cells 1 and 2**.

```console
  MCP server: https://…/api/2.0/mcp/functions/agents_labs/retail

  as admin@…
  tools discovered: 2
    - agents_labs__retail__get_order_summary
    - agents_labs__retail__revenue_by_region
```

Every Unity Catalog function in the schema, exposed as an MCP tool with the schema
[Lab 5A](lab-5a-governed-uc-function.md) showed you. Two JSON-RPC methods matter:
`tools/list` and `tools/call`.

---

### Step 2 — Become the service principal (10 min)

Run **cell 3**. It reads the SP's credentials from the secret scope and exchanges them for
a short-lived token via OAuth M2M.

```console
  client_id : [REDACTED]
  secret    : [REDACTED]

  got an SP token, expires in 3600s
```

> 💡 **Look at those two lines.** The notebook *asked* to print the client id and secret.
> Databricks replaced both with `[REDACTED]` — `dbutils.secrets.get` taints the value, and
> anything derived from it is redacted in every output, including ones you did not
> anticipate.
>
> This is why credentials belong in a secret scope rather than a notebook cell: the
> platform stops you leaking them **into the notebook's saved output**, which is where
> they would otherwise live forever.

---

### Step 3 — Discover as it (7 min)

Run **cell 4**. Same server, same request, different bearer token.

```console
  as the service principal
  tools discovered: 1
    - agents_labs__retail__get_order_summary

  you see    : 2
  it sees    : 1
  invisible  : ['agents_labs__retail__revenue_by_region']
```

**The tool list is not a constant.** It is a view over Unity Catalog, computed per caller.

---

### Step 4 — Call the tool it was never granted (10 min)

Run **cell 5**, and read the last line carefully.

```console
  as you:
   get_order_summary   OK      {"is_truncated":false,"columns":["order_id","status", …
   revenue_by_region   OK      {"is_truncated":false,"columns":["region","month", …

  as the service principal:
   get_order_summary   OK      {"is_truncated":false,"columns":["order_id","status", …
   revenue_by_region   ERROR   {'code': -32602, 'message': "BAD_REQUEST: Function
                               'agents_labs.retail.revenue_by_region' not found"}
```

> 🚨 **Not "permission denied". Not "forbidden". Not found.**
>
> To an identity without the grant, that function **does not exist**. Unity Catalog is not
> refusing the call — it is answering honestly about a namespace that, for this principal,
> contains one function.

---

### Step 5 — Why this beats a check at call time (10 min)

Read **cell 6**. The usual design shows the agent every tool and checks permissions when it
calls one. Compare:

| | Check at call time | **Filtered discovery** |
|---|---|---|
| What the model sees | every tool | only its own |
| Failure mode | tries, gets denied, retries, apologises | never considers it |
| Prompt-injection surface | *"call the admin tool"* is attemptable | the tool is not in its context |
| Leak | the tool's **name and description** disclose it exists | nothing |
| Where the rule lives | your application code | **the grant** |

> 🚨 **The tool list is context, and context leaks.** A tool named
> `approve_refund_above_limit` tells a determined user something about your system even if
> every call is refused. Filtered discovery means there is nothing to tell.

> 💡 **Notice where the rule lives.** You wrote no permission code. The boundary is a
> `GRANT`, inherited by **every** consumer of that schema — this notebook, an agent, a job,
> a colleague's app.
>
> That is the same contrast as [Lab 4B](../session-4-genie/lab-4b-genie-in-an-agent.md):
> the Genie Knowledge Store travelled to a new consumer because it lived with the agent,
> while [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md)'s
> `audience` filter did **not**, because it lived in the caller — and
> [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md)
> pays for that with a disclosed document.
>
> **A grant is the strongest version of that idea**: enforced by the platform, not by
> anyone remembering.

---

### Step 6 — Try it (5 min)

1. Grant the SP `EXECUTE` on `revenue_by_region`, re-run cell 4, watch the tool **appear**.
   Revoke it and watch it vanish. **No redeploy, no restart.**
2. Run `SELECT * FROM agents_labs.retail.orders` as the SP. It has no `SELECT` — yet
   `get_order_summary` reads that table and works. Definer's rights.
3. Look again at cell 3's output. Did the secret print?

---

## 6. What You Learned

| You saw… | in Step | proof |
|---|---|---|
| UC functions are MCP tools automatically | 1 | `tools/list` returns 2 |
| Secrets are redacted from notebook output | 2 | `[REDACTED]` on a deliberate print |
| Two identities get **different tool lists** | 3 | 2 vs 1 |
| The ungranted tool is **invisible**, not forbidden | 4 | `Function … not found` |
| Discovery is governed, not just execution | 4 | nothing to attempt |
| The tool list is context, and context leaks | 5 | a name discloses a capability |
| The rule lives in a grant, not in code | 5 | no permission code written |
| Grants take effect without redeploying | 6 | revoke and re-run |

## 7. What You Hand In

Run experiment 1 and paste the tool list before and after. One `GRANT` changing what an
agent can perceive — with no code change and no restart — is the shortest demonstration of
governed tooling you will have.

---

**Next:** [Lab 6A — Build an Evaluation Dataset](../session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md)
