# Agents on Databricks — Lab Course

Fifteen hands-on labs for a seven-session course on building, governing, evaluating and operating AI agents on Databricks, plus a graded offline capstone.

Every lab in this repository was **built and run against a live Azure Databricks workspace**. Each transcript in a lab document is real output, each screenshot is a real terminal or a real console page, and each gotcha box records something that actually broke during the build.

The workspace began as a **trial** and was upgraded to **Premium** to finish the two steps a trial refuses — Model Serving deployment (Lab 6B Step 5) and Agent Bricks (Lab 7B Step 5). Both labs show the trial refusal *and* the working result, because which one you hit depends on your own SKU.

## Course map

| Session | Lab | What it establishes | Tested |
|---|---|---|---|
| **1 · Agent architecture** | [1A — Workflow or Agent?](session-1-agent-architecture/lab-1a-workflow-vs-agent.md) | When an agent is the wrong answer. Four scenarios, a worksheet to hand in, two of them traps. | paper exercise |
| | [1B — A Minimal Agent](session-1-agent-architecture/lab-1b-minimal-agent.md) | **In a Databricks notebook.** The execution loop, a tool that fails, an approval gate in code, and a prompt-injection attempt. | ✅ live · notebook |
| | [1C — Build Your First Agent in the UI](session-1-agent-architecture/lab-1c-build-your-first-agent-in-the-ui.md) | The same agent with **no code**, in the AI Playground. One button generates the whole lifecycle — and leaves **7 `TODO`s**. | ✅ live · UI walkthrough |
| **2 · Platform-agnostic design** | [2A — Two Sources](session-2-platform-agnostic/lab-2a-retrieval-and-tools.md) | **Notebook.** Core logic with no platform imports, proved by an AST check. Two sources the agent sequences itself. | ✅ live · notebook |
| | [2B — Swap the Retriever](session-2-platform-agnostic/lab-2b-adapter-swap.md) | **Notebook.** Same core, unrelated retriever. Identical-quality answers, and keyword scores the right document at **0.0000**. | ✅ live · notebook |
| **3 · Grounding and RAG** | [3A — Vector Search Index](session-3-grounding-and-rag/lab-3a-vector-search-index.md) | **Notebook.** Delta Sync, managed embeddings, CDF + PK, and **4/4 known-answer retrieval checks**. | ✅ live · notebook |
| | [3B — A Traced RAG Agent](session-3-grounding-and-rag/lab-3b-traced-rag-agent.md) | **Notebook.** Traces as UC Delta tables you query in SQL — and **87% of the latency turns out to be the model**. | ✅ live · notebook |
| **4 · Genie** | [4A — Build, Curate and Measure a Genie Agent](session-4-genie/lab-4a-genie-space.md) | **Console.** Benchmarks with ground-truth SQL, the Knowledge Store, and knowledge mining. Curation measured: **0% → 100%**. | ✅ live |
| | [4B — Genie Inside an Agent](session-4-genie/lab-4b-genie-in-an-agent.md) | **Notebook.** Genie as one tool among several — and the 4A curation is **inherited** by a consumer that knows nothing about it. | ✅ live · notebook |
| **5 · Tools and governance** | [5A — The Function *Is* the Tool](session-5-tools-and-governance/lab-5a-governed-uc-function.md) | **Notebook.** Read back the tool schema Databricks generated from a `COMMENT`. `EXECUTE` without `SELECT`. | ✅ live · notebook |
| | [5B — Two Identities, Two Tool Lists](session-5-tools-and-governance/lab-5b-mcp-and-access-control.md) | **Notebook.** The same MCP server returns **2 tools to you and 1 to the agent** — and the ungranted one is *"not found"*, not *"denied"*. | ✅ live · notebook |
| **6 · Evaluation and deployment** | [6A — An Evaluation Dataset](session-6-evaluation-and-deployment/lab-6a-evaluation-dataset.md) | **Notebook.** Negative cases, six scorers — and the judge penalising a **correct refusal**. | ✅ live · notebook |
| | [6B — Optimize and Deploy](session-6-evaluation-and-deployment/lab-6b-optimize-and-deploy.md) | **Notebook.** The headline metric improved — and **none of the gain came from the agent**. Deployed and queried over HTTP. | ✅ live · notebook |
| **7 · Operations and multi-agent** | [7A — A Supervisor and Two Workers](session-7-operations-and-multi-agent/lab-7a-multi-agent-supervisor.md) | **Notebook.** The supervisor **re-delegates** after learning a fact, inverting the answer — and a starved worker answers confidently instead of refusing. | ✅ live · notebook |
| | [7B — Canaries, Rollback and Agent Bricks](session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md) | **Notebook + console.** A real defect the canary finds — and the **control column proves the change did not cause it**. Alias rollback; a no-code brick **disclosing an internal document**. | ✅ live · notebook |
| **Capstone** | [Returns Adjudication Agent](capstone/capstone-brief.md) | **Notebook.** Independent build, graded by a notebook that `%run`s your submission. Verified at **100/100** and **30/100**. | ✅ live · notebook |

## Two routes through the platform

The course teaches the same capabilities twice, on purpose.

**The UI route** is what a Databricks user reaches for first: the [AI Playground](session-1-agent-architecture/lab-1c-build-your-first-agent-in-the-ui.md) for prototyping, [Genie](session-4-genie/lab-4a-genie-space.md) for data questions, [Agent Bricks](session-7-operations-and-multi-agent/lab-7b-rollout-and-agent-bricks.md) for a no-code assistant. It is fast, and Lab 1C gets to a working tool-calling agent in fifteen minutes without typing anything.

**The code route** is every other lab. It exists because the UI route stops at the same place every time — the point where the platform hands you a scaffold full of `TODO`s and a set of defaults that are *defaults*, not decisions. Lab 1C ends by generating a 463-line notebook with seven of them; Lab 7B shows what one unfilled blank costs.

Teach 1C first if your audience is new to Databricks. Teach 1B first if they are new to agents.

## The thread through the labs

The labs are not independent exercises. Each one answers a question the previous one raised, using one dataset engineered so the questions are literally answerable:

- **2B** shows two retrievers producing identical answers, so you cannot judge retrieval by reading outputs.
- **6A** measures that gap: correctness `1.00`, retrieval relevance `0.20`.
- **6B** tunes it, and finds the aggregate metric misleading.
- **1A** asks as a design exercise why Nordics revenue dropped. **4A** answers it from the data — Genie independently found Nordic Office Group's seating orders going £16,500 → £0.
- **7A**'s supervisor needs two delegations to reach the DOC-007 fit-out exception. The **capstone** grader awards points for retrieval good enough to surface it in one.
- **3A** filters retrieval to `audience: customer`. **7B** points a no-code Agent Bricks assistant at that same index and it discloses `DOC-006`, an `agent_only` document — because the filter lived in the caller, not in a grant.
- **4A** benchmarks Genie and finds it **0% accurate** on a question whose prose answer looked perfect — three reasonable assumptions, none of them yours. Curation moves it to 100%, and the question is never reworded.
- **4B** then proves that curation is **inherited**: a notebook that knows nothing about the console work gets all three rules. Put beside 3A → 7B, where a caller-side filter is *not* inherited and leaks a document, it is the same lesson from both directions.

Two lessons arrive repeatedly, from different directions.

**The judge is usually the thing that is broken.** Lab 6A's scorer penalised correct refusals; Lab 7B's refusal detector scored correct refusals as failures; the capstone rubric awards a toolless agent full marks on the approval gate for escalating out of ignorance. All three are documented as defects rather than smoothed over.

**A control that lives in application code is a convention.** Lab 5B puts tool access in Unity Catalog grants, where a new consumer inherits it. Lab 3A puts document access in a query-time filter, where a new consumer does not — and Lab 7B is that new consumer, disclosing an internal refund threshold nobody intended to publish.

## Repository layout

```
session-{1..7}-*/
  lab-*.md              the student guide
  code/                 everything the guide runs
capstone/
  capstone-brief.md     the brief and the rubric
  grade.py              the grader — read it, build against it
  reference/            a 100/100 solution and a 30/100 one
tools/
  lab_common.py         credential resolution shared by every lab
  run_sql.py            SQL runner with a quote-aware statement splitter
  check_links.py        verifies every link and image resolves
  setup/*.sql           catalog, data, chunking, UC functions, grants
  screenshots/          the capture driver and what went wrong building it
artifacts/lab-*/
  screenshots/          real terminals, one per documented step
  evidence/             full transcripts behind every quoted console block
source/                 the course outline and original lab plan
TEARDOWN.md             how to remove everything, and what is shared
```

## Setting up a workspace

The labs need: a Unity Catalog catalog, a SQL warehouse, a Vector Search endpoint, Foundation Model API access, and a Genie space. Full provisioning, including the parts that are not obvious:

- Unity Catalog **Default Storage blocks `CREATE CATALOG` from SQL**. You need an ADLS Gen2 container, an access connector with a system-assigned managed identity, `Storage Blob Data Contributor`, a storage credential and an external location, then `CREATE CATALOG … MANAGED LOCATION`. RBAC takes about a minute to propagate.
- `databricks-agents` **will not build on Python 3.14** (`whenever` has no wheel). Use 3.11 or 3.12. The failure is silent: scorers return `No module named 'databricks.agents'` buried in per-trace assessments.
- **Model Serving and Agent Bricks are unavailable on trial workspaces.** Labs 1A–7A and the capstone run fully on a trial; **6B Step 5 and 7B Step 5 need Premium or Enterprise**. Azure allows trial → premium only, never the reverse.

```bash
python -m venv .venv312 --python=python3.12
./.venv312/bin/pip install "mlflow[databricks]" databricks-agents databricks-sdk \
    databricks-ai-search openai

export DATABRICKS_PROFILE=agents-labs
export LAB_WAREHOUSE_ID=<sql warehouse id>
export LAB_GENIE_SPACE=<genie space id>

./.venv312/bin/python tools/run_sql.py tools/setup/01_seed_retail.sql
# … 02 through 06, in order
./.venv312/bin/python tools/check_links.py
```

## Delivery notes

- **Per session:** two labs, 45–55 minutes each, sized for a 2-hour session with discussion.
- **Capstone:** ~4 hours offline, self-graded by `capstone/grade.py`, 80/100 to pass.
- **Cost:** the whole course is Foundation Model API calls, one Vector Search endpoint and one small SQL warehouse. No GPU. Steps 6B-5 and 7B-5 add a serving endpoint and an Agent Bricks agent, both billed while they exist.
- **Instructor prep:** run `tools/check_links.py`, then Lab 1B and Lab 3A, before any cohort. Those two prove auth, the catalog, the index and the model endpoint in about ten minutes.

## Teardown

See [`TEARDOWN.md`](TEARDOWN.md). Note that the metastore may be **shared with other catalogs** — deleting the resource group does not remove Unity Catalog objects, and those must be dropped separately.
# Agent_on_Databricks-training
