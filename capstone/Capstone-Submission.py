# Databricks notebook source
# MAGIC %md
# MAGIC # Capstone — My Submission
# MAGIC
# MAGIC **This notebook is yours. Replace everything below the setup cell with your own
# MAGIC agent.**
# MAGIC
# MAGIC The grader runs `%run ./Capstone-Submission` and then calls **one function**:
# MAGIC
# MAGIC ```python
# MAGIC adjudicate(request: str) -> dict
# MAGIC ```
# MAGIC
# MAGIC It must return:
# MAGIC
# MAGIC ```python
# MAGIC {
# MAGIC   "decision":  "approve" | "refuse" | "escalate",
# MAGIC   "reason":    str,            # one or two sentences
# MAGIC   "citations": list[str],      # e.g. ["DOC-001", "DOC-007"]
# MAGIC   "order":     dict | None,    # whatever your order lookup returned
# MAGIC }
# MAGIC ```
# MAGIC
# MAGIC `order` must be non-`None` when the request names an order that exists. The grader
# MAGIC uses it to confirm you actually looked the order up rather than parsing the
# MAGIC reference out of the text.
# MAGIC
# MAGIC > ⚠️ **Do not rename this notebook.** The grader `%run`s it by name.
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC The cells below are a **worked reference**. Read them after you have attempted your
# MAGIC own, or delete them and start from scratch.

# COMMAND ----------

# MAGIC %pip install -q databricks-ai-search openai
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

import json, os, re, warnings
import mlflow
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementParameterListItem
from mlflow.entities.trace_location import UnityCatalog
from openai import OpenAI
from databricks.ai_search.client import VectorSearchClient

warnings.filterwarnings("ignore", message=".*serializer warnings.*")

CATALOG, SCHEMA = "agents_labs", "retail"
MODEL = "databricks-claude-sonnet-5"
ESCALATION_THRESHOLD = 5000.0          # the brief fixes this number

_w = WorkspaceClient()
_tok = _w.config.authenticate()["Authorization"].removeprefix("Bearer ")
_client = OpenAI(api_key=_tok, base_url=f"{_w.config.host}/serving-endpoints")
_ix = VectorSearchClient(workspace_url=_w.config.host, personal_access_token=_tok,
                         disable_notice=True).get_index(
    endpoint_name="agents-labs-vs", index_name=f"{CATALOG}.{SCHEMA}.support_chunks_idx")

SYSTEM = f"""You adjudicate product return requests for an office furniture retailer.

Process, in order:
  1. If the request names an order reference, call lookup_order for it.
  2. Call search_policy to find the written rules that apply.
  3. Decide.

Decide exactly one of:
  approve   - the policy clearly permits the return
  refuse    - the policy clearly forbids it, OR the policy does not cover the
              question at all. Never guess a rule that is not in the excerpts.
  escalate  - the refund value is {ESCALATION_THRESHOLD:.0f} GBP or more. A human
              must sign off regardless of how clear the policy is.

Reply with ONLY a JSON object, no prose around it:
  {{"decision": "...", "reason": "...", "citations": ["DOC-001"]}}"""


@mlflow.trace(span_type="TOOL")
def lookup_order(order_ref: str) -> dict:
    """The governed UC function from Lab 5A is the tool."""
    r = _w.statement_execution.execute_statement(
        warehouse_id=[x for x in _w.warehouses.list()][0].id,
        statement=f"SELECT * FROM {CATALOG}.{SCHEMA}.get_order_summary(:ref)",
        # a plain dict is rejected here: the SDK calls .as_dict() on each item
        parameters=[StatementParameterListItem(name="ref", value=order_ref)],
        wait_timeout="50s")
    cols = [c.name for c in r.manifest.schema.columns]
    rows = (r.result.data_array or []) if r.result else []
    if not rows:
        return {"found": False, "order_ref": order_ref}
    rec = dict(zip(cols, rows[0]))
    rec["found"] = True
    rec["refund_value_gbp"] = float(rec.get("revenue") or 0)
    return rec


@mlflow.trace(span_type="RETRIEVER")
def search_policy(query: str, k: int = 3) -> list:
    r = _ix.similarity_search(query_text=query, columns=["doc_id", "title", "chunk"],
                              filters={"audience": "customer"}, num_results=k)
    return [{"doc_id": x[0], "title": x[1], "text": x[2]}
            for x in (r.get("result", {}).get("data_array", []) or [])]


TOOLS = [
    {"type": "function", "function": {
        "name": "lookup_order",
        "description": "Look up one order by its reference: status, item, units, refund "
                       "value in GBP, region and the customer's loyalty tier.",
        "parameters": {"type": "object",
                       "properties": {"order_ref": {"type": "string",
                                                    "description": "e.g. ORD-1007"}},
                       "required": ["order_ref"]}}},
    {"type": "function", "function": {
        "name": "search_policy",
        "description": "Search the customer-facing policy documents. Returns excerpts "
                       "with their document ids.",
        "parameters": {"type": "object", "properties": {"query": {"type": "string"}},
                       "required": ["query"]}}},
]
IMPL = {"lookup_order": lambda a: lookup_order(a["order_ref"]),
        "search_policy": lambda a: search_policy(a["query"])}


def _text(m):
    c = m.content
    if c is None: return ""
    if isinstance(c, str): return c
    return "\n".join(b.get("text", "") for b in c
                     if isinstance(b, dict) and b.get("type") == "text").strip()


def _parse(raw: str) -> dict:
    """The model is asked for bare JSON. It sometimes fences it anyway."""
    m = re.search(r"\{.*\}", raw, re.S)
    if not m:
        return {"decision": "refuse", "reason": f"unparseable: {raw[:120]}", "citations": []}
    try:
        d = json.loads(m.group(0))
    except json.JSONDecodeError:
        return {"decision": "refuse", "reason": f"unparseable: {raw[:120]}", "citations": []}
    d.setdefault("citations", [])
    d.setdefault("reason", "")
    return d


@mlflow.trace(span_type="AGENT")
def adjudicate(request: str, max_steps: int = 5) -> dict:
    """The entry point the grader calls."""
    messages = [{"role": "system", "content": SYSTEM},
                {"role": "user", "content": request}]
    order = None
    for _ in range(max_steps):
        msg = _client.chat.completions.create(
            model=MODEL, messages=messages, tools=TOOLS, max_tokens=900
        ).choices[0].message
        messages.append(msg.model_dump(exclude_none=True))
        if not msg.tool_calls:
            out = _parse(_text(msg))
            out["order"] = order
            # The threshold is a control, not a suggestion. Enforce it in code so a
            # prompt injection or a sloppy completion cannot talk its way past it.
            if order and order.get("refund_value_gbp", 0) >= ESCALATION_THRESHOLD:
                if out.get("decision") != "escalate":
                    out["reason"] = (f"Refund value GBP {order['refund_value_gbp']:.2f} is "
                                     f"at or above the GBP {ESCALATION_THRESHOLD:.0f} "
                                     f"sign-off threshold. " + out.get("reason", ""))
                out["decision"] = "escalate"
            return out
        for tc in msg.tool_calls:
            args = json.loads(tc.function.arguments or "{}")
            res = IMPL[tc.function.name](args)
            if tc.function.name == "lookup_order" and res.get("found"):
                order = res
            messages.append({"role": "tool", "tool_call_id": tc.id,
                             "content": json.dumps(res, default=str)[:6000]})
    return {"decision": "refuse", "reason": "no decision within step budget",
            "citations": [], "order": order}


print("  adjudicate() is defined — the grader will call it")
