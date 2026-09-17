# SAP Datasphere Portfolio

CSN/JSON exports of Datasphere objects across 5 lab spaces via @sap/datasphere-cli. Demonstrates CI/CD pattern: export from source tenant, version in Git, import to target.

## Spaces

### FINCLOSE_STAGING
Procurement analytics on SEPM demo data. Bronze/Silver/Gold layers, intelligent lookup for product matching. Now shares TF_PO_HEADER_ITEM and incoming_products to FIN_LAB_FILES for cross space data product flow.

### FIN_LAB_FILES
BDC Object Store custom data product lab. PROD_LANDING product master and PO_SILVER_UC4_DELTA procurement Delta table, landed via transformation flows from FINCLOSE_STAGING and UC4_PROC.

### BDC_SPACE
Consumption layer over the Object Store data product. V_PROD_LANDING view and AM_PROD_CONSUMED analytic model prove read path back into Datasphere semantic modeling.

### LB_DSP
Sales analytics lab. Customer master harmonization from CRM/ERP, sales silver, customer match via intelligent lookup.

### UC4_PROC
Supplier risk analytics. S/4HANA purchasing replication, delayed schedule line views, XGBoost risk scoring integrated with SAP AI Core.

## Commands

Export: datasphere objects TYPE read -y SPACE_ID -f OBJECT_ID > OBJECT_ID.json

Import: datasphere objects TYPE create -y TARGET_SPACE -F OBJECT_ID.json

## Prerequisites
- @sap/datasphere-cli
- OAuth Client with Interactive Usage purpose (App Integration)
- User with Space Administrator or DW Integrator role
