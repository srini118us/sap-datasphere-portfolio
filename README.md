# SAP Datasphere Portfolio

CSN/JSON exports of SAP Datasphere objects across three lab spaces, extracted via the official @sap/datasphere-cli. Demonstrates the CI/CD pattern used by SAP data architects: export from source tenant, version in Git, import to target tenant.

## Spaces

### FINCLOSE_STAGING (11 objects)
Procurement analytics lab. SEPM demo purchase order data through Bronze, Silver, Gold layers, with intelligent lookup for product matching.

### LB_DSP (19 objects)
Sales analytics lab. Customer master data harmonization from CRM and ERP sources, sales silver transformation, customer match via intelligent lookup.

### UC4_PROC (10 objects)
Supplier risk analytics. S/4HANA purchasing replication, delayed schedule line views, XGBoost risk scoring integrated with SAP AI Core. Related article: Your AI Agent Is Not Wrong, It Is Bounded (Medium, Aug 2026).

## Extract command
datasphere objects analytic-models read -y SPACE_ID -f OBJECT_ID > OBJECT_ID.json

## Import command
datasphere objects analytic-models create -y TARGET_SPACE -F OBJECT_ID.json

## Prerequisites
- @sap/datasphere-cli
- OAuth Client with Interactive Usage purpose in Datasphere App Integration
- User with Space Administrator or DW Integrator role
