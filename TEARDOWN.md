# Teardown

> ✅ **Executed on 2026-09-30.** Everything below was carried out and verified:
> no Databricks workspace remains, `rg-agents-on-databricks` is deleted, and the
> `agents_labs` catalog is dropped from the shared metastore. The 11 pre-existing
> catalogs (`dbacademy*`, `bread_academy`, `demo-catalog`, …) were left untouched.
>
> **Order used**, which matters:
> 1. Serving endpoints, Vector Search endpoints and indexes, SQL warehouse
> 2. `agents_labs` catalog (force), external location, storage credential
> 3. Secret scope, service principals
> 4. Metastore assignment
> 5. Azure resource group
>
> The Agent Bricks endpoint (`ka-b233b9d0-endpoint`) refused a direct delete —
> *"Please delete the tile to delete all associated endpoints"* — and went with the
> workspace. **One Agent Bricks agent creates two endpoints**, so budget for that.
>
> Local: the `agents-labs`, `agents-account` and `agents-restricted` profiles were
> removed from `~/.databrickscfg` (a timestamped backup was written alongside it).
> The `.venv` and `.venv312` directories are gitignored and were left in place.

---


Everything created for building these labs, and how to remove it.
The labs themselves are parameterised — they do not depend on any of this.

## Azure (one command removes all of it)

```bash
az group delete -n rg-agents-on-databricks --yes --no-wait
```

That resource group contains:

| Resource | Name |
|---|---|
| Databricks workspace (**premium** SKU, upgraded from trial) | `dbx-agents-labs` |
| Managed resource group | `databricks-rg-dbx-agents-labs-1p1zpq0e4cjuy` |
| ADLS Gen2 storage account | `stagentslabs1588` |
| Databricks access connector | `ac-agents-labs` |

## Unity Catalog — IMPORTANT, this is a *shared* metastore

The workspace was attached to the **existing** `eastus` metastore
`79599d4f-1385-479a-9715-1021f2e7e329`, which already held the `dbacademy`
catalogs from other workspaces. Deleting the resource group does **not** remove
UC objects. Remove only what this course created:

```bash
databricks catalogs delete agents_labs --force -p agents-labs
databricks external-locations delete sc-agents-loc -p agents-labs
databricks storage-credentials delete sc-agents-labs -p agents-labs
databricks account metastore-assignments delete 7405616584960877 79599d4f-1385-479a-9715-1021f2e7e329 -p agents-account
```

Dropping the catalog with `--force` takes its schemas, tables, functions,
volumes, **registered models, model aliases and the MLflow trace tables** with
it. The full inventory inside `agents_labs.retail`, for the record:

| Kind | Objects |
|---|---|
| Tables | `customers`, `orders`, `support_docs`, `support_chunks` |
| Functions | `get_order_summary`, `revenue_by_region` |
| Vector index | `support_chunks_idx` |
| Registered models | `support_agent` (v1–v3, aliases `@champion` `@challenger` `@previous`), `returns_adjudicator` (v1, `@champion`) |
| Trace tables | `<experiment_id>_otel_{spans,logs,metrics,annotations}`, one set per traced experiment |
| Inference table | `support_agent_payload` — created automatically by the AI Gateway when the agent was deployed; contains real request and response payloads |

Nothing else in that metastore was touched.

## Objects that live outside the catalog

These are **not** removed by dropping the catalog, and are not in the resource
group either. Delete them before the workspace goes:

```bash
# Vector Search endpoint — billed while it exists, so remove it even if you
# keep the workspace
databricks vector-search-endpoints delete-endpoint agents-labs-vs -p agents-labs

# Agent serving endpoint from Lab 6B Step 5 — billed, scale-to-zero or not
databricks agents delete-deployment agents_labs.retail.support_agent -p agents-labs

# Agent Bricks Knowledge Assistant from Lab 7B Step 5 — delete from the UI:
#   Agents -> retail-policy-assistant -> ... -> Delete
#   id b233b9d0-a43d-4911-a392-b8da74d7085c
# It also creates its own serving endpoint; deleting the agent removes it.

# Genie space and SQL warehouse (workspace objects)
#   Genie space   01f1bc6b0a4f1c6d8269cc9c1ec2af08   — delete from the UI
databricks warehouses delete c8729519c456cb8e -p agents-labs

# Service principal created for Lab 5B least-privilege probes
databricks service-principals list -p agents-labs   # find the id, then:
# databricks service-principals delete <id> -p agents-labs
```

MLflow experiments under `/Users/<you>/agents-labs-*` are workspace files and
go with the workspace. If you keep the workspace, remove them from the UI:
`agents-labs-3b`, `-6-deploy`, `-7a`, `-7b`, `-capstone`, `-capstone-models`.

> ⚠️ **Three objects keep costing money after you stop using the course**, and
> none of them is in the resource group or in the catalog, so both of the "one
> command removes everything" steps miss all three: the **Vector Search
> endpoint**, the **agent serving endpoint**, and the **Agent Bricks agent**.

> ⚠️ **The workspace is on the Premium SKU.** It was upgraded from trial to
> complete Lab 6B Step 5 and Lab 7B Step 5. Azure does not allow premium →
> trial, so the only way to stop Premium-rate charges is to delete the
> workspace.

## Local

```bash
# remove the two profiles added to ~/.databrickscfg
#   [agents-labs]     workspace
#   [agents-account]  account console
rm -rf "/Users/hadez/Documents/Company/training content/Agent_on_Databricks/.venv"
rm -rf "/Users/hadez/Documents/Company/training content/Agent_on_Databricks/.venv312"
```

## Order

1. Agent Bricks agent, agent serving endpoint, Vector Search endpoint — all billed, and nothing else deletes them.
2. UC objects — catalog, external location, storage credential.
3. Metastore assignment.
4. The Azure resource group.

Delete the UC objects **first**, then the resource group. Dropping the storage
account before the catalog leaves the catalog pointing at storage that no longer
exists, which makes it awkward to delete cleanly.
