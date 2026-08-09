# NovaCart Customer 360 Data Platform

A production-style data engineering project that integrates e-commerce, customer, payment, return, inventory, marketing, and web analytics data into a tested **Snowflake dimensional warehouse**.

---

## Project Goal

NovaCart solves the challenge of fragmented business data across multiple operational systems.

The platform creates a unified analytics layer for questions such as:

- Which customers and products generate the most revenue?
- Which payment methods fail most often?
- Which products have the highest return rates?
- Which warehouses are experiencing stockouts?
- Which marketing campaigns generate the strongest ROAS?
- How does customer web engagement translate into orders?

---

### Data Sources

- E-commerce orders and order items
- Customers
- Products
- Payments
- Returns
- Daily inventory
- Warehouses
- Marketing campaigns
- Web analytics
- Unstructured business documents

---

## Architecture

![NovaCart Architecture](assets/novacart-final-architecture.png)

---

## Technology Stack

**Data Engineering**
- Python
- SQL
- AWS S3
- Snowflake
- Snowpipe
- dbt
- dbt-utils

**Orchestration & Processing**
- Apache Airflow
- Incremental loading
- SCD Type 2

**Analytics**
- Power BI
- Dimensional modelling
- Star schema

**AI Data Engineering**
- Document ingestion
- Embeddings
- Vector search
- Retrieval-Augmented Generation
- AI evaluation

---

## Snowflake Data Layers

### RAW
Preserves source data for traceability and reprocessing.

### STAGING
Standardizes, cleans, casts, and prepares source records.

### INTERMEDIATE
Applies reusable business logic and creates conformed analytical models.

### MARTS
Provides business-ready fact and dimension tables for analytics.

---

## Dimensional Model

### Dimensions

| Model | Grain |
|---|---|
| `dim_customers` | One row per customer |
| `dim_products` | One row per product |
| `dim_campaigns` | One row per campaign |
| `dim_date` | One row per calendar date |
| `dim_warehouses` | One row per warehouse |

### Facts

| Model | Grain |
|---|---|
| `fct_orders` | One row per order |
| `fct_order_items` | One row per order line |
| `fct_payments` | One row per payment attempt |
| `fct_returns` | One row per return transaction |
| `fct_inventory_snapshot` | Latest inventory position per product |
| `fct_inventory_daily` | Product × warehouse × date |
| `fct_campaign_performance` | One row per campaign |
| `fct_customer_engagement` | One row per engaged customer |

---

## Data Quality

The project includes extensive dbt testing for:

- Primary-key uniqueness
- Not-null validation
- Referential integrity
- Fact-table grain
- Accepted business values
- Revenue reconciliation
- Payment-status logic
- Return-status logic
- Inventory reconciliation

Example validations include:

```text
gross_amount = quantity × unit_price

net_revenue = captured_revenue - refunds

closing_stock =
opening_stock + received - sold - damaged

inventory_value = closing_stock × unit_cost
```

---

## Key Engineering Features

- Multi-source data integration
- Layered Snowflake architecture
- Reusable dbt intermediate models
- Star-schema dimensional modelling
- Transaction and snapshot fact tables
- Surrogate dimension keys
- Business-rule testing
- Historical inventory modelling
- Secrets excluded from version control
- Compute-conscious development

---

## Implementation Status

| Capability | Status |
|---|---|
| Snowflake RAW / STAGING layers | ✅ Complete |
| Intermediate business models | ✅ Complete |
| dbt transformations | ✅ Complete |
| Data-quality tests | ✅ Complete |
| Dimensional marts | ✅ Complete |
| Payment & return facts | ✅ Complete |
| Historical inventory modelling | ✅ Complete |
| AWS S3 / Python ingestion foundation | ✅ Complete |
| Snowpipe auto-ingestion | 🔄 Next |
| Incremental dbt models | 🔄 Next |
| SCD Type 2 | 🔄 Next |
| Airflow orchestration | 🔄 Next |
| Power BI dashboards | 🔄 Next |
| AI / RAG extension | 🔄 Next |

---

## AI-Driven Extension

The final platform will combine structured Snowflake marts with unstructured business documents.

The assistant will support:

- Source-grounded business questions
- Inventory and revenue analysis
- Campaign analysis
- Payment and return insights
- Internal knowledge retrieval

---

## Next Milestones

1. Implement Snowpipe auto-ingestion
2. Convert suitable pipelines to incremental processing
3. Add SCD Type 2 history tracking
4. Add Apache Airflow orchestration and monitoring
5. Build Power BI semantic model and dashboards
6. Implement embeddings, vector search, and RAG
7. Build and evaluate the NovaCart AI Data Operations Assistant

---

## Repository Structure

```text
novacart-customer-360-data-platform/
│
├── assets/
│   └── novacart-final-architecture.png
│
├── dbt_novacart/
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   │
│   ├── tests/
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── package-lock.yml
│
├── airflow/
├── scripts/
├── data/
├── .gitignore
└── README.md
```

---

## Current Milestone

The current milestone completes the core analytical warehouse:

```text
Multi-source data
      ↓
Snowflake
      ↓
dbt transformations
      ↓
Tested dimensional marts
```

The next phase focuses on production automation, BI, and AI-driven analytics.

---

## Author

Built as a hands-on data engineering portfolio project focused on production thinking, dimensional modelling, data quality, analytics engineering, orchestration, and AI-enabled data platforms.
