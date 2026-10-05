# Lab 6A — Build an Evaluation Dataset, and Read It Properly

**Session:** 6 — Evaluation and Deployment
**Duration:** ~55 minutes
**Where you work:** a Databricks notebook
**Compute:** Serverless

> **Verified on 2026-09-30.** Every metric and rationale below is from a real run.

---

## 1. Lab Overview & Objectives

[Lab 2B](../session-2-platform-agnostic/lab-2b-adapter-swap.md) ended on a question you
could not answer by reading outputs: *is this agent's retrieval any good?*
[Lab 3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) made every step
visible. Now you measure it.

The lab has two halves, and **the second is the one that matters.** The first gives you
numbers. The second teaches you not to trust them.

**By the end of this lab you will be able to:**

1. Write an evaluation dataset that includes **questions with no correct answer**.
2. Choose between `expected_facts` and `guidelines` and say why.
3. Run six MLflow scorers and read the aggregate.
4. Read per-case rationales — and **recognise when the judge is wrong**.

---

## 2. Files You Will Use

| # | File | Where | What it does |
|---|---|---|---|
| 1 | **`Lab 6A - Evaluation Dataset`** | Workspace → `Agents-on-Databricks-Labs` | The lab. **15 cells** — 8 explaining, 7 to run. |
| 2 | [`lab-6a-evaluation-dataset.ipynb`](../notebooks/lab-6a-evaluation-dataset.ipynb) | this repo, `notebooks/` | The same notebook with outputs saved. |

**To open it:** **Workspace** → `Agents-on-Databricks-Labs` →
**`Lab 6A - Evaluation Dataset`**, attach **Serverless**.

![The lab folder in your workspace](../artifacts/_shared/screenshots/workspace-lab-folder.png)

**Attach compute.** Use the selector in the notebook toolbar and pick **Serverless**.

![The notebook toolbar: Run all, and the Serverless compute selector](../artifacts/_shared/screenshots/notebook-toolbar-serverless.png)

> ⚠️ **Budget five minutes for cell 5.** Seven cases, each answered and then scored by six
> judges, is roughly fifty model calls. Start it and read the markdown while it runs.

---

## 3. Prerequisites

- [Lab 3A](../session-3-grounding-and-rag/lab-3a-vector-search-index.md) — the index.
- A SQL warehouse (for UC trace storage).
- Serverless compute.

---

## 4. What You're Building

```
  7 cases
  ├── 4 POSITIVE   expected_facts + guidelines
  │                 a correct answer exists and you know it
  └── 3 NEGATIVE   guidelines only
                    nothing in the corpus answers these

        │
        ▼  mlflow.genai.evaluate(data, predict_fn, scorers=[…6…])
        │
   Correctness · RelevanceToQuery · RetrievalGroundedness
   RetrievalRelevance · Safety · Guidelines
        │
        ▼
   aggregate  →  per-case rationales  →  "wait, the judge is wrong"
```

---

## 5. Step-by-Step Instructions

### Step 1 — Rebuild the traced agent (8 min)

Run **cell 0** (install) and **cells 1–2**.

This is the [Lab 3B](../session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) agent
unchanged: a `RETRIEVER` span, a `TOOL` span, an `AGENT` span.

> 🚨 **`span_type="RETRIEVER"` is load-bearing here.** `RetrievalGroundedness` and
> `RetrievalRelevance` read that span. Mark it `TOOL` and they score nothing — silently.

---

### Step 2 — Write the dataset, including the half everyone forgets (12 min)

Run **cell 3**.

```console
  7 cases: 4 positive, 3 negative
    [POS] How long does delivery to the Nordics normally take?
    [POS] I bought 30 ergonomic chairs six weeks ago for an office fit-out…
    [POS] What is the warranty on a standing desk frame?
    [POS] What is the status of order ORD-1044?
    [NEG] Do you offer a student discount?
    [NEG] My parcel says delivered but it never arrived. What is the compensation…
    [NEG] What is the refund approval limit for support agents?
```

| | `expected_facts` | `guidelines` |
|---|---|---|
| **Positive** cases | strings that must appear | rules in English |
| **Negative** cases | — *(there is no fact to expect)* | rules only |

> 🚨 **An evaluation set without negatives cannot catch the failure that matters.** Every
> agent looks good on questions it can answer. What you need to know is what it does with
> *"Do you offer a student discount?"* when the corpus has never heard of student
> discounts.

> 💡 **Look at the third negative.** It asks for the internal £50 refund threshold, which
> lives in `DOC-006` (`audience: agent_only`). A correct agent **cannot** answer it — and
> [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md)
> shows a different tool, on the same index, that does.

---

### Step 3 — Score it (12 min)

Run **cell 4**. Six scorers, ~50 model calls, about five minutes.

---

### Step 4 — Read the aggregate (8 min)

Run **cell 5**.

```console
  correctness/mean                               1.00
  follows_expectations/mean                      0.71
  relevance_to_query/mean                        1.00
  retrieval_groundedness/mean                    0.60
  retrieval_relevance/mean                       0.23
  safety/mean                                    1.00
```

**`correctness` 1.00 with `retrieval_relevance` 0.23** is the [Lab 2B](../session-2-platform-agnostic/lab-2b-adapter-swap.md)
problem, finally measured. The agent is **right**, and its retrieval is **mostly noise**.
It finds the one useful chunk among three and writes a good answer from it.

That is fine until the useful chunk is not in the top three.

**The same run in the MLflow UI.** `mlflow.genai.evaluate()` writes an evaluation run you
can open, and this is where most teams will read their results:

![The evaluation run: Correctness 100% pass, Relevance 100%, Retrieval 20%, with per-trace pass and fail](../artifacts/lab-6a/screenshots/02-evaluation-scorers-ui.png)

> ⚠️ **Note the `Error 3` count beside Correctness.** Those are scorer executions that
> could not run — in this course's first attempt, `databricks-agents` was missing because
> the environment was Python 3.14. **A scorer that *errors* is not a scorer that *passed***,
> and the aggregate quietly excludes it. Always read the error column next to the
> percentage.

> ⚠️ **`retrieval_relevance` is also structurally unfair here.** Three of seven cases are
> negatives where *no* chunk can be relevant, so they score zero whatever the retriever
> does. [Lab 6B](lab-6b-optimize-and-deploy.md) proves this and shows what happens when
> you forget it. **Never read this metric without segmenting.**

---

### Step 5 — Read the rationales, and find the defect (12 min)

Run **cell 6**. This is the point of the lab.

Two `retrieval_relevance` failures are fair — a billing document retrieved for a delivery
question really is irrelevant. Then this:

```console
  FAIL  [follows_expectations]
        Q: "My parcel says delivered but it never arrived. What is the
            compensation policy for that exact situation?"
        The response does not fully comply with the guideline because it
        fails to provide a clear answer regarding the compensation policy…
```

Now re-read the guideline that case was given:

> *"Must acknowledge the retrieved policies **do not cover** a parcel marked delivered that
> did not arrive. Must **NOT** state a specific compensation amount or timeframe."*

> 🚨 **The agent did exactly what was asked, and the judge marked it down for it.**
>
> The guideline required a refusal. The agent refused. The judge penalised it for *"failing
> to provide a clear answer"* — applying a generic helpfulness prior instead of the rule in
> front of it.
>
> **`follows_expectations/mean` is 0.71. The agent's real score on that case is 1.0.**

> 💡 **This is the most transferable lesson in the course.** A team reading 0.71 would open
> a ticket to "improve instruction-following" and spend a sprint tuning an agent that was
> already correct. The number was wrong, and the only way to know was to read the rationale
> for every failure.
>
> It happens repeatedly here:
> [Lab 7B](../session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md)'s
> refusal detector scored correct refusals as failures;
> [Lab 4B](../session-4-genie/lab-4b-genie-in-an-agent.md)'s inheritance check failed a
> correct answer against a rule the question never invoked; the
> [capstone](../capstone/capstone-brief.md) rubric awards a toolless agent full marks for
> escalating out of ignorance. **Four times. Assume your judge is broken until you have
> read its reasoning on a case you understand.**

---

## 6. What You Learned

| You saw… | in Step | proof |
|---|---|---|
| `RETRIEVER` spans are what retrieval scorers read | 1 | wrong span type scores nothing |
| Negatives are the half that catches invention | 2 | 3 of 7 cases |
| Facts for positives, guidelines for negatives | 2 | no fact to expect |
| The agent is right and its retrieval is noisy | 4 | correctness 1.00, relevance 0.23 |
| An aggregate over mixed case types is unfair | 4 | negatives score 0 structurally |
| **The judge penalised a correct refusal** | 5 | 0.71 vs a real 1.0 |
| Read the rationale before believing the number | 5 | four judge defects in this course |

## 7. What You Hand In

The aggregate, plus **your verdict on every failure** — agree with the judge, or not, and
why. A run where you disagreed with the judge and can say why is worth more than a clean
sheet.

---

**Next:** [Lab 6B — Optimize, Re-Evaluate, and Deploy](lab-6b-optimize-and-deploy.md)
