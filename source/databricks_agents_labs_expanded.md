# Hands-On Labs — AI Agents and Agents on Databricks (Expanded: 14 Labs / 7 Sessions + Capstone)

Each session's single combined lab is split into two focused labs — one per distinct sub-skill — giving a mid-session checkpoint instead of one long build. Session structure, platform split (Sessions 1–2 agnostic, Sessions 3–7 Databricks), and the capstone are unchanged. Nothing new was invented: every lab maps to a bullet already in the outline, including a few (human approval, prompt-injection awareness, safe rollout/versioning) that were previously mentioned but had no dedicated hands-on.

---

## Session 1 — AI Agent Architecture and Design (Platform-Agnostic)

### Lab 1A — When to Use a Workflow vs. an Agent (Design Exercise)
**Maps to:** LLM applications, workflows, RAG, and agents: when to use each; agent components; context engineering

**What needs to be built:** A set of 3–4 scenarios (some better solved as a fixed workflow, some genuinely needing agentic behavior). Participants classify each and sketch the agent components (instructions, model, tools, state) for the ones that need an agent.

**Visible end result:** A **written classification with reasoning** for each scenario, including at least one correctly identified as *not* needing an agent — the judgment call that's easy to skip if design and build are merged into one activity.

---

### Lab 1B — Minimal Tool-Calling Agent with Memory, Failure Handling & Human Approval
**Maps to:** Tool schemas, input validation, retries, stopping conditions; grounding, prompt injection awareness, human approval

**What needs to be built:** A minimal agent with one callable tool, basic memory, retry/stopping-condition logic, a human-approval gate before a sensitive tool call executes, and a deliberate prompt-injection attempt embedded in a test input.

**Visible end result:** Participants watch the agent **correctly handle a failing tool call, pause for human approval before a sensitive action, and resist the embedded injection attempt** — three distinct failure modes tested in one build, not just the happy path.

---

## Session 2 — Platform-Agnostic Agent Implementation

### Lab 2A — Illustrative Agent with Document Retrieval & a Structured/API Tool
**Maps to:** Common architecture across local, cloud, and managed platforms; connecting document retrieval, structured data, and APIs

**What needs to be built:** An agent combining document retrieval with a tool call against structured data or an external API, built with portable logic (adapters kept separate from core agent code).

**Visible end result:** Participants **ask a question that requires both the retrieved document context and a live API/data call to answer correctly** — proof the agent genuinely combines both sources, not just one.

---

### Lab 2B — Adapter Swap & Portability Validation
**Maps to:** Portable agent logic and model, retrieval, and tool adapters; authentication, runtime configuration, and portability limitations

**What needs to be built:** Swap one adapter from Lab 2A (e.g., a different retrieval backend) without touching the agent's core logic; adjust runtime auth/config as needed.

**Visible end result:** The **same test question gets an equivalent correct answer before and after the swap** — portability demonstrated directly, not asserted.

---

## Session 3 — Introducing Databricks; Data Grounding and Agent Construction

### Lab 3A — Data Preparation & Vector Search Index Build
**Maps to:** Delta data preparation, chunking, embeddings, and metadata; Vector Search index creation, synchronization, filtering, and retrieval quality

**What needs to be built:** Prepared Delta data, chunked and embedded, indexed into Vector Search with metadata filters; a retrieval-quality spot-check against known-answer queries.

**Visible end result:** Participants **run a filtered query and confirm the top retrieved chunks are actually the correct, relevant ones** — the index proven functional before any agent is built on top of it.

---

### Lab 3B — Traced RAG Agent with Source Citations
**Maps to:** Agent authoring, foundation model endpoints, AI Functions overview; MLflow agent logging, tracing, and source citations

**What needs to be built:** An agent authored against a foundation model endpoint that queries the Lab 3A index and cites sources, with MLflow tracing wired in.

**Visible end result:** Participants **inspect the MLflow trace and see the exact retrieved chunks and citations behind a given answer** — the retrieval step made fully auditable.

---

## Session 4 — Databricks Genie

### Lab 4A — Set Up & Query a Genie Space
**Maps to:** What Genie is; Genie architecture and grounding; Unity Catalog semantics (metric views, domains, Pages)

**What needs to be built:** A Genie space configured against governed UC data (metric views/domains), tested with natural-language business questions.

**Visible end result:** Participants **ask a natural-language question directly in Genie and get a correct, governed answer** sourced from UC semantics — before any agent integration is added.

---

### Lab 4B — Genie Code: Calling Genie from an Agent Workflow
**Maps to:** How Genie is launched, configured, and used; Genie Code for agent building; where Genie fits alongside agents

**What needs to be built:** An agent that calls the Lab 4A Genie space as a tool (via Genie Code) as part of a larger conversation, rather than participants querying Genie standalone.

**Visible end result:** Participants **watch an agent invoke Genie mid-conversation and incorporate the governed answer into its own response** — Genie working as a callable capability, not just a standalone UI.

---

## Session 5 — Tools and Governance

### Lab 5A — Build a Governed Tool from a Unity Catalog Function
**Maps to:** Agent tools using functions, governed tables, and APIs; Unity Catalog functions, least-privilege access, and execution identities

**What needs to be built:** A tool built from a UC function or governed table, scoped to a least-privilege execution identity.

**Visible end result:** The agent **successfully calls the tool and gets correct, governed data back**, with the execution identity visible in the call — the least-privilege scope configured and confirmed working before it's tested against.

---

### Lab 5B — MCP Integration & Access-Control Testing
**Maps to:** MCP concepts, tool discovery, authentication, and invocation; tool validation, error handling, and approval for actions

**What needs to be built:** A preconfigured MCP integration added for tool discovery/invocation, plus a deliberate test attempting to use the Lab 5A tool outside its granted scope.

**Visible end result:** The agent is **explicitly denied when the test attempts to exceed its scope** — the governance boundary proven enforced, not just configured, which is the harder and more important half of this session.

---

## Session 6 — Evaluation, Optimization and Deployment

### Lab 6A — Build an Evaluation Dataset & Run Baseline MLflow Agent Evaluation
**Maps to:** Evaluation datasets, expected outcomes, and negative test cases; Agent Evaluation with MLflow: AI-assisted scoring and human feedback; groundedness, correctness, tool success, latency, and token usage

**What needs to be built:** An evaluation dataset including negative/edge test cases, scored against a Session 3 or 5 agent via MLflow Agent Evaluation.

**Visible end result:** A **baseline evaluation report** — scores for groundedness, correctness, tool success, latency, and tokens — establishing the "before" state the next lab will measurably improve on.

---

### Lab 6B — Optimize for Cost/Latency, Re-Evaluate, and Deploy to Model Serving
**Maps to:** Token optimization and cost-saving techniques; latency challenges and how to reduce them; trace-based diagnosis and a measured improvement cycle; agent registration and deployment to Model Serving

**What needs to be built:** An optimization pass on the Lab 6A agent (caching, retrieval tuning, prompt design, streaming/parallelism), re-evaluated on the same dataset, then registered in Unity Catalog and deployed to Model Serving with endpoint checks.

**Visible end result:** A **side-by-side before/after evaluation showing measurably lower cost and/or latency**, followed by the agent **live on a Model Serving endpoint that participants hit directly and get a correct response from** — the full "diagnose → improve → ship" loop in one lab.

---

## Session 7 — Operations, Multi-Agent Systems, Agent Bricks & Best Practices

### Lab 7A — Multi-Agent Supervisor/Worker Flow with State Passing
**Maps to:** Multi-agent systems: orchestration, delegation, and supervisor/worker patterns; coordinating agents and passing state/context between them

**What needs to be built:** A supervisor agent that delegates sub-tasks to at least two worker agents and combines their results, with explicit state/context passed between them.

**Visible end result:** Participants **submit one request and watch the supervisor delegate to two different workers, then combine both results into a single coherent final answer** — multi-agent coordination made visible step-by-step.

---

### Lab 7B — Agent Bricks Configuration & Safe Rollout Comparison
**Maps to:** Agent Bricks: task configuration, synthetic data, and automated evaluation/tuning; Agent Framework versus Agent Bricks; safe rollout, versioning, rollback, and data freshness

**What needs to be built:** An Agent Bricks task configured for the same use case as Lab 7A (task config, synthetic data, auto-evaluation), then a deliberate new-version rollout of it, with a rollback exercise if the new version underperforms.

**Visible end result:** Participants **watch Agent Bricks auto-tune and evaluate itself** — a direct, hands-on contrast to Lab 7A's manually built supervisor flow — and separately **push a new version live, then roll it back**, proving the versioning/rollback mechanism works before it's ever needed for real.

---

## Capstone — Offline, Independent (4 hours, after Session 6) — Unchanged

**What needs to be built:** An agent (new or extended) for a faculty-selected or agreed use case, including enterprise data grounding, a governed tool, and error handling; an evaluation dataset with a demonstrated improvement cycle; a deployed version with documented access controls.

**Visible end result:** A submitted package — code/notebooks, evaluation results, deployment evidence, and a short demonstration — applying the full course journey independently. Automated grading given ~1,000–1,200 expected participants.

---

## Summary Table

| Lab | Session | Platform | Core Deliverable |
|---|---|---|---|
| 1A. Workflow vs. Agent Design Decision | 1 | Agnostic | Correct classification, including a rejected non-agent scenario |
| 1B. Tool-Calling Agent + Approval + Injection Test | 1 | Agnostic | Handles tool failure, human approval gate, and resists injection |
| 2A. Retrieval + Structured/API Tool | 2 | Agnostic | Answer requires both retrieved context and a live data call |
| 2B. Adapter Swap & Portability Validation | 2 | Agnostic | Same correct answer before/after an adapter swap |
| 3A. Data Prep & Vector Search Index Build | 3 | Databricks | Filtered query returns correct, relevant chunks |
| 3B. Traced RAG Agent with Citations | 3 | Databricks | MLflow trace shows retrieved chunks + citations |
| 4A. Set Up & Query a Genie Space | 4 | Databricks (Genie) | Correct governed NL answer directly from Genie |
| 4B. Genie Code in an Agent Workflow | 4 | Databricks (Genie) | Agent calls Genie mid-conversation, incorporates the answer |
| 5A. Governed Tool from a UC Function | 5 | Databricks | Tool call succeeds with correct, governed data |
| 5B. MCP Integration & Access-Control Testing | 5 | Databricks | Out-of-scope access attempt explicitly denied |
| 6A. Evaluation Dataset & Baseline Scoring | 6 | Databricks | Baseline groundedness/correctness/latency/token report |
| 6B. Optimize, Re-Evaluate & Deploy | 6 | Databricks | Measured before/after improvement + live endpoint |
| 7A. Multi-Agent Supervisor/Worker Flow | 7 | Databricks | Supervisor delegates to 2 workers, combines results |
| 7B. Agent Bricks + Safe Rollout/Rollback | 7 | Databricks | Self-tuned Agent Bricks task; new version pushed and rolled back |
| Capstone. Independent Build & Deploy | Offline | Databricks | Full grounded/governed/evaluated/deployed agent, auto-graded |

---

## Notes on the Expansion

- **Sessions 1–2 stay lighter** (2 labs each, same as before) since they're intentionally the shorter, platform-agnostic on-ramp — expanding them further would work against the outline's own "4 hours agnostic, 10 hours Databricks" balance.
- **Session 6 and 7 now explicitly cover bullets that had no hands-on before:** human approval and prompt-injection awareness (1B), safe rollout/versioning/rollback (7B) — these were named in the original outline's bullet points but weren't exercised in the single combined lab per session.
- **Pacing check needed:** 2 labs per 2-hour session is tighter than the original 1-per-session design, especially in Session 6 and 7 where the underlying work (optimization + deployment; multi-agent + Agent Bricks + rollout) is already substantial. Worth a dry run to confirm both labs fit comfortably, or consider trimming 6B/7B's scope slightly if time is tight in delivery.
