# UC4 — Intelligent Procurement Agent (SAP AI Journey)

**Status: COMPLETE and PUBLISHED**

End-to-end use case combining live S/4HANA data with a custom XGBoost model,
delivered through a Joule Studio agent. All three layers resolved and wired
end to end; results published to Medium and LinkedIn.

## Architecture at a glance

```
User (chat)
     │
     ▼
┌─────────────────────────────────────────┐
│ Joule Agent: Risk Analyzer Agent        │
│  (Gemini 3.5 Flash)                     │
└──┬──────────────┬──────────────┬───────┘
   ▼              ▼              ▼
getDelayed    getPurchase    getSupplierRiskScore
Purchase      OrderSuppliers  (calls AI Core)
Orders        (+ GetSupplierDetails
              on-demand)
   │              │              │
   ▼              ▼              ▼
S/4HANA (v2 OData)              AI Core deployment
Private Cloud                   XGBoost model (KServe / FastAPI)
                                    ▲
                        ┌───────────┴─────────┐
                        │ S3 (dataset, model) │
                        │ Docker (images)     │
                        │ GitHub (this repo)  │
                        └─────────────────────┘
     │
     ▼
Datasphere (V_SUPPLIER_RISK_SCORES → AM_SUPPLIER_RISK_SCORES)
     │
     ▼
SAC Story: "UC4 Supplier Scorecard"
```

## Status

| Step | Component | Status |
|---|---|---|
| 1 | Joule baseline agent + 3 tools (supplier leaderboard from live S/4 data) | ✅ COMPLETE |
| 2 | XGBoost model trained + served on AI Core, callable via HTTPS | ✅ COMPLETE |
| 3 | Joule skill `getSupplierRiskScore` wrapping AI Core inference | ✅ COMPLETE — resolved |
| 4 | Datasphere semantic view + Analytic Model | ✅ COMPLETE |
| 5 | SAC scorecard | ✅ COMPLETE — "UC4 Supplier Scorecard" |
| 6 | SBPA >1M approval workflow | ⏳ Not built (deferred, out of published scope) |
| 7 | BDC / Databricks comparative deployment | ⏳ Optional / not pursued |

## Layer 1 — Joule baseline

- Tools: `getDelayedPurchaseOrders` (schedule lines, `$filter` delayed +
  `$top=200`), `getPurchaseOrderSuppliers` (new skill, GET `/A_PurchaseOrder`
  `$top=200`), `GetSupplierDetails` (demoted to on-demand enrichment).
- Result: full 11-supplier leaderboard from 42 delayed POs, bounded by
  `$top=200` — documented as a key article insight (a real production
  constraint), not a bug.
- Top delay-causing suppliers: USSU-VSF06 "VF Vendor 06" (34 lines / 7,881
  PC), USSU-VSF08 (7,880 PC), EV Parts Inc. (4,755 PC), WaveCrest Labs,
  Domestic US Suppliers. Earth Link Communication (BP 1) confirmed NOT among
  the delay-causers.

## Layer 2 — AI Core XGBoost

- Scenario `supplier-prediction-tutorial`, resource group `default`.
- Serving deployment `d14608980b877b4d` (rebuilt after a prior instance was
  deleted).
- Model artifact `d04761ba-29b0-4d4b-bfc3-6516c9a1511f` — S3-persisted,
  survives deployment deletion.
- Predict endpoint: `<deployURL>/v2/predict` (the double `/v2` is correct —
  AI Core gateway path + FastAPI route).
- Metrics: accuracy 0.661, AUC 0.652.
- Docker images `srini117us/supplier-prediction-{train,serve}:01` on Docker
  Hub — no rebuild needed.
- `vendor_category` encoder accepts only `['FINISH','PACK','RAW','SERVICE']`;
  unknown values return a FastAPI error, confirming the call reached the
  container.

## Layer 3 — Joule → AI Core wiring

- Resolved: the AI-Resource-Group header blocker is moot now the deployment
  lives in resource group `default`.
- Destination `AICORE_INFERENCE` points at the deployment URL; action test
  returns 200 OK with a real prediction, and the agent chained test works.
- Identical risk scores across suppliers is expected and documented as a
  limitation: "features are representative, not derived."

## Datasphere / SAC

- SQL view `V_SUPPLIER_RISK_SCORES` (built with `CAST` — CSV import types
  numerics as text) and Analytic Model `AM_SUPPLIER_RISK_SCORES`.
- SAC story "UC4 Supplier Scorecard": supplier risk table beside a "Delayed
  Lines per Supplier" bar chart.

## Published outputs

- Medium article: *"Your AI Agent Isn't Wrong. It's Bounded."*
- LinkedIn post.
- Detailed architecture diagram (Medium/repo) plus a sparse three-lane
  diagram (LinkedIn/talk).
- Repo: `sap-ai-journey` (GitHub `srini118us`). `supplier-prediction-tutorial/`
  stays at repo root (AI Core sync path, unchanged); all UC4 artifacts live
  under `uc4-procurement-agent/`. Three commits made — one pre-commit scan
  catch removed a live AI Core client secret before pushing.

## Key lessons (article-worthy)

1. **AI Core is a three-contracts orchestrator.** It hosts none of your code,
   data, or model. Every failure is one of three named-thing mismatches
   (registry secret, object store secret, git/YAML).
2. **A workflow template without `inputs.artifacts` / `outputs.artifacts`
   trains a model into the void.** The pod runs, exits, and nothing survives.
3. **Build-from-Scratch actions require output lists named after HTTP status
   codes** (e.g., `200`). Lists named `default` or `success` compile to no
   consumable schema.
4. **Joule Studio uses destination environment variables as the runtime
   binding mechanism** — defined in Project Properties → Environment
   Variables, mapped to real BTP destinations at deploy time.
5. **Every OData v2 `Edm.Time` field arrives as an ISO 8601 duration**
   (`PT00H00M00S`) — set API Format to None on the action's output schema.
6. **In PowerShell, single-quote credentials containing `$`, `|`, or `!`** —
   double quotes silently mangle them.

## Known / deferred limitations

- `top_factors` mapping gap — deliberately deferred.
- A minor probability discrepancy — deliberately deferred.
- SBPA >1M approval workflow and BDC/Databricks comparative deployment were
  not pursued for the published version.

## References

- SAP Community — Custom Agentic Chatbot with SAP AI Core and Joule Studio Part 3(1)
- SAP-samples/teched2025-AI163 exercise 4 (destination environment variable pattern)
- SAP RIG — Building a Procurement Agent for S/4HANA Cloud Private Edition (baseline)

Full bibliography and build log in `docs/UC4_Handoff_Aug21.docx`; final
published version and commit history live in `sap-ai-journey/uc4-procurement-agent/`.
