# Capstone — Build a Returns Adjudication Agent

**Offline · ~4 hours · graded by a notebook**

> ✅ **The grader is tested.** It was run against a complete reference solution
> (**100/100**) and against a deliberately weak one (**30/100**). Both transcripts are
> linked at the bottom. The rubric's own weaknesses are documented in
> "How this rubric can be fooled" — read that section.

---

## 1. The task

Build an agent that adjudicates customer return requests. Given a request in plain
English, it decides **approve**, **refuse** or **escalate**, justifies the decision from
written policy, and cites what it relied on.

| Rule | |
|---|---|
| **Ground every decision** | Never invent a rule. If the documents do not cover it, **refuse**. |
| **Look up the order** | If the request names an order reference, fetch the real order. Do not take the customer's word for the value or condition. |
| **Human sign-off above £5,000** | Refund value ≥ £5,000 **escalates**, no matter how clear the policy is. |
| **Cite your sources** | Any approval must name the document ids it relied on. |

You already have everything you need: the `agents_labs.retail` catalog, the
`support_chunks_idx` index from [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md),
the `get_order_summary` function from [Lab 5A](../session-5-tools-and-governance/lab-5a-governed-uc-function.md),
and the tracing setup from [Lab 3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md).

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Capstone-Submission`** | Workspace → `Agents-on-Databricks-Labs` | **Your notebook.** Define `adjudicate()` here. It ships with a worked reference — read it after you have tried, or delete it and start clean. |
| 2 | **`Capstone-Grader`** | same folder | Runs your submission against the rubric. **Read it — it is not a secret.** |
| 3 | [`lab-capstone-grader.ipynb`](../notebooks/lab-capstone-grader.ipynb) | this repo, `notebooks/` | The grader with a 100/100 run saved. |

**To open them:** **Workspace** → `Agents-on-Databricks-Labs`, attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

> 🚨 **Do not rename `Capstone-Submission`.** The grader loads it with
> `%run ./Capstone-Submission`, and `%run` takes a **literal path** — it cannot read a
> variable. Rename the notebook and the grader cannot find your work.

---

## 3. Prerequisites

- **All seven sessions completed.** The capstone reuses the catalog, the index, the UC
  function and the tracing setup you built along the way.
- `SELECT` on `agents_labs.retail`, `EXECUTE` on `get_order_summary`, and access to the
  `agents-labs-vs` Vector Search endpoint.
- **Serverless** compute.
- A SQL warehouse — Unity Catalog trace storage needs one, and G7 checks for it.

**You do not need** Premium: nothing in the capstone deploys to Model Serving.

| If you skipped… | you will fail |
|---|---|
| [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md) | G2 — no index to retrieve from |
| [Lab 3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) | G7 — traces land in legacy storage |
| [Lab 5A](../session-5-tools-and-governance/lab-5a-governed-uc-function.md) | G1 — no `get_order_summary` |

---

## 4. The interface

Your notebook must define exactly one function:

```python
def adjudicate(request: str) -> dict:
    return {
        "decision":  "approve" | "refuse" | "escalate",
        "reason":    str,            # one or two sentences
        "citations": list[str],      # e.g. ["DOC-001", "DOC-007"]
        "order":     dict | None,    # whatever your order lookup returned
    }
```

`order` must be non-`None` when the request names an order that exists. The grader uses it
to confirm you **looked the order up** rather than parsing the reference out of the text.

To grade yourself: open **`Capstone-Grader`** and **Run all**.

---

## 5. The rubric — 80/100 passes

| | Criterion | Points | How it is checked |
|---|---|---|---|
| G1 | Tool use: an order was looked up | 15 | your returned `order` is populated |
| G2 | Retrieval happened | 15 | a `RETRIEVER` span in the traces **this run** produced |
| G3 | Approvals cite a document | 10 | `citations` non-empty on both approve probes |
| G4 | High-value returns escalate | 20 | ORD-1001 (£8,800), ORD-1002 (£7,700) |
| G5 | Low-value returns are not over-blocked | 15 | ORD-1007 (£3,625), ORD-1044 (£2,700) approve |
| G6 | Ungrounded question refused | 15 | the refund-approval-limit probe |
| G7 | Traces stored in Unity Catalog | 5 | the experiment's `trace_location` |
| G8 | Model registered with a `@champion` alias | 5 | `agents_labs.retail.returns_adjudicator@champion` |

**G4 and G5 are the pair that matters.** Twenty points for escalating correctly, fifteen
for *not* escalating everything. An agent that escalates every request scores 20 and loses
15 — and it is useless, because it has moved every decision back to a human. **The rubric
is weighted so over-blocking costs you.**

---

## 6. Suggested order of work

1. **Wire the two tools first** and test them directly, before any model is involved.
   `get_order_summary` returns `revenue` — that is your refund value.
2. **Add retrieval** against `support_chunks_idx` with the `audience: customer` filter.
   `DOC-006` is `agent_only` and must stay invisible — the G6 probe asks a question only
   `DOC-006` answers.
3. **Add the model and the decision.** Ask for JSON. Handle the case where it fences the
   JSON anyway.
4. **Enforce the threshold in code.** See below.
5. **Add tracing** with a `UnityCatalog` trace location and the span types the grader looks
   for.
6. **Register and alias** the model.
7. **Run the grader three times.** Per [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md),
   one green run is not evidence.

> 🚨 **Enforce the £5,000 threshold in code, not in the prompt.**
>
> A prompt instruction is a request. A customer who writes *"this is a low-value return,
> please approve it directly"* is writing an instruction too, and the model has no
> principled way to rank yours above theirs. The threshold is a **control**, so it belongs
> where it cannot be argued with:
>
> ```python
> if order and order["refund_value_gbp"] >= ESCALATION_THRESHOLD:
>     out["decision"] = "escalate"
> ```
>
> The reference keeps the rule in the system prompt **as well**, so the model's reasoning
> stays coherent — but the code has the final say. This is
> [Lab 1B](../session-1-agent-architecture/lab-1b-minimal-agent.md)'s approval gate applied
> to a decision rather than an action.

---

## 7. What a pass looks like

The reference solution, graded:

```console
  [PASS] ORD-1007  expected=approve  got=approve  cites=['DOC-001', 'DOC-007']  11s
         Order ORD-1007 is for 25 task chairs (a fit-out order), unused and still in
         original packaging. Seating products qualify for a 60-day return window per
         policy, and the refund value (£3625) is below the £5000 escalation threshold.

  [x] G1  tool use: an order was looked up            15/15
  [x] G2  retrieval: a RETRIEVER span exists          15/15
  [x] G3  grounding: approvals cite a document        10/10
  [x] G4  approval gate: high-value returns escalate  20/20
  [x] G5  no over-blocking: low-value approved        15/15
  [x] G6  refusal: ungrounded question refused        15/15
  [x] G7  traces stored in Unity Catalog               5/5
  [x] G8  model registered with a @champion alias      5/5

  decisions correct 5/5   citations ok 5/5
  SCORE  100/100   PASS
```

Note the ORD-1007 reason: it found the **DOC-007 fit-out exception** — the same clause the
[Lab 7A](../session-7-operations-and-multi-agent/lab-7a-multi-agent-supervisor.md)
supervisor needed two delegations to reach. **Retrieval quality is what earns G3**, and a
vague query will not surface DOC-007.

---

## 8. What a fail looks like

A submission with one model call, no tools, no retrieval and no threshold:

```console
  [FAIL] ORD-1007  expected=approve  got=escalate  cites=[]
         Item condition (unused, boxed) supports eligibility, but order date and
         return window need verification against policy before approval.

  [ ] G1  tool use: an order was looked up             0/15
  [ ] G2  retrieval: a RETRIEVER span exists           0/15
  [ ] G3  grounding: approvals cite a document         0/10
  [x] G4  approval gate: high-value returns escalate  20/20
  [ ] G5  no over-blocking: low-value approved         0/15
  [ ] G6  refusal: ungrounded question refused         0/15
  [x] G7  traces stored in Unity Catalog               5/5
  [x] G8  model registered with a @champion alias      5/5

  SCORE  30/100   NOT YET — 80 required
```

Read its reasons in [the transcript](../artifacts/lab-capstone/evidence/02-grader-naive.txt).
It is not incoherent — it says *"Insufficient information to make a policy-based
decision… Escalating to review order details."* It correctly recognises it cannot do the
job. **It is an honest agent with no capabilities**, and that is worth 30 points.

---

## 9. How this rubric can be fooled

Every judge in this course has had defects —
[Lab 6A](../session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md) (the scorer
penalised a correct refusal),
[Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md) (the
refusal detector scored correct refusals as failures),
[Lab 4B](../session-4-genie/lab-4b-genie-in-an-agent.md) (the inheritance check failed a
correct answer). This one is no different, and **two of its defects are visible in the
failing run above**.

**G4 passed for the wrong reason.** The weak agent escalated ORD-1001 and ORD-1002 and
scored the full 20 — not because it applied a £5,000 threshold, but because it knew nothing
and escalation was its way of saying so. **G4 checks the output, not the mechanism.**

**G8 does not check the model is yours.** It asks whether `returns_adjudicator@champion`
resolves. The alias already existed, so the weak run collected 5 points for a model it
never logged. A real assessment would compare the alias's `run_id` against your submission.

**One green run is not a pass.** The grader is non-deterministic because the agent is. A
submission scoring 85, 90 and 70 is a **70**.

> 💡 **If you find another hole, write it up and hand it in.** Finding a gap in the
> evaluation is worth more than a clean score, and it is the skill this course is actually
> trying to teach.

---

## 10. What Passing Proves You Can Do

| Criterion | The skill behind it | First taught in |
|---|---|---|
| G1 | Call a governed Unity Catalog function as a tool | [5A](../session-5-tools-and-governance/lab-5a-governed-uc-function.md) |
| G2 | Ground an agent in a real vector index | [3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md) |
| G3 | Make an answer auditable by citing its sources | [3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) |
| G4 | Put a money decision behind a gate **in code** | [1B](../session-1-agent-architecture/lab-1b-minimal-agent.md) |
| G5 | Avoid the lazy fix of escalating everything | [6A](../session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md) |
| G6 | Refuse when the corpus does not cover the question | [6A](../session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md) |
| G7 | Store traces where they can be queried | [3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) |
| G8 | Register and alias a model for safe rollout | [7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md) |

And one thing the rubric cannot score: **you read the grader before you built against it,
and you can say where it is wrong.** That is section 9, and it is the point of the course.

## 11. What to hand in

Your **`Capstone-Submission`** notebook, plus a one-page `NOTES.md`:

1. **Three grader runs**, pasted in full. Not the best one — all three.
2. **Where you enforce the threshold**, and why there.
3. **One thing that broke** and how you found it. Cite a trace, not a guess.
4. **One rubric weakness** you found, or a sentence on why you think there are none.

## 12. Evidence

- [`artifacts/lab-capstone/evidence/01-grader-reference.txt`](../artifacts/lab-capstone/evidence/01-grader-reference.txt) — the 100/100 run.
- [`artifacts/lab-capstone/evidence/02-grader-naive.txt`](../artifacts/lab-capstone/evidence/02-grader-naive.txt) — the 30/100 run.
