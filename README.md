# SAP Datasphere Portfolio

Object-level exports from three SAP Datasphere spaces, extracted via the official @sap/datasphere-cli. Demonstrates the CI/CD pattern SAP data architects use: export from source tenant, version in Git, import to target tenant. SaaS environments cannot be mirrored to Git wholesale, but object definitions (views, analytic models, replication flows, task chains, intelligent lookups) can and this repo is the working proof.

## Structure

| Folder | Type | Objects | Details |
|---|---|---|---|
| FINCLOSE_STAGING | Project Financial Close Copilot | 11 | Full data layer, medallion architecture, SAC dashboard. See folder README. |
| UC4_PROC | Project Intelligent Procurement Agent | 10 | Joule agent + XGBoost via AI Core. See folder README. |
| LB_DSP | Exploratory labs, customer + sales harmonization | 19 | Object exports only |

## Why CSN/JSON matters

Every JSON file in this repo is a runnable definition. Re-import to any Datasphere tenant with one command:

    datasphere objects analytic-models create -y TARGET_SPACE -F AM_PO_ANALYTICS.json

This is the DevOps pattern for SaaS analytics platforms, the same idea behind Databricks Asset Bundles, dbt manifests, Terraform state.

## Extract command

    datasphere objects <object-type> read -y <SPACE_ID> -f <OBJECT_ID> > <OBJECT_ID>.json

Object types: analytic-models, views, local-tables, replication-flows, task-chains, transformation-flows, intelligent-lookups, data-access-controls.

## Prerequisites

- @sap/datasphere-cli (Node.js 18+)
- OAuth Client in Datasphere App Integration with Purpose: Interactive Usage (browser-based authorization_code flow)
- User with Space Administrator or DW Integrator role

## Related repos

- srini118us/sap-ai-journey, SAP AI Core, Joule, GenAI Hub work
- srini118us/databricks-journey, Databricks companion work

## Author

Srinivasa, SAP Solution Architect transitioning toward AI Architect roles. LinkedIn article on the UC4 architecture: "Your AI Agent Isn't Wrong. It's Bounded." (Medium, Aug 2026).
