# Data Lineage

## High-Level Architecture

```mermaid
flowchart LR
    ERP[ERP CSV/API/CDC] --> Stage[External Stage]
    Stage --> Pipe[Snowpipe]
    Pipe --> Raw[RAW VARIANT Tables]
    Raw --> Stream[Snowflake Streams]
    Stream --> Staging[dbt Staging Models]
    Staging --> Vault[Data Vault Hubs Links Satellites]
    Vault --> Marts[Dimensional Marts]
    Marts --> BI[Executive BI / Finance KPIs]
    Marts --> Features[Snowpark Feature Tables]
    Raw --> Observability[Freshness and SLA Views]
    Marts --> Observability
```

## dbt Model-Level Lineage

```mermaid
flowchart LR
    %% ── Sources ──────────────────────────────────────────────
    subgraph SOURCES["📥 Sources (Snowflake RAW schema)"]
        direction TB
        SRC_CUSTOMERS[(RAW_ERP_CUSTOMERS)]
        SRC_ORDERS[(RAW_ERP_ORDERS)]
    end

    %% ── Staging ──────────────────────────────────────────────
    subgraph STAGING["🔄 Staging"]
        direction TB
        STG_CUST[stg_erp_customers]
        STG_CUST_HIST[stg_erp_customers_history]
        STG_ORD[stg_erp_orders]
    end

    %% ── Raw Vault ────────────────────────────────────────────
    subgraph VAULT["🏛️ Raw Vault"]
        direction TB
        HUB_CUST[hub_customer]
        HUB_ORD[hub_order]
        LINK[link_customer_order]
        SAT[sat_customer_details]
    end

    %% ── Dimensional Marts ────────────────────────────────────
    subgraph MARTS["📊 Marts"]
        direction TB
        DIM_CUST[dim_customer]
        FACT_REV[fact_revenue]
    end

    %% ── Features ─────────────────────────────────────────────
    subgraph FEATURES["🤖 Features"]
        FEAT_REV90[feature_customer_revenue_90d]
    end

    %% ── Observability ────────────────────────────────────────
    subgraph OBS["🔭 Observability"]
        SLA[model_sla_status]
    end

    %% ── Quality ──────────────────────────────────────────────
    subgraph QUALITY["✅ Quality"]
        direction TB
        Q_RECON[quality_order_reconciliation]
        Q_ANOM[quality_revenue_anomaly_daily]
    end

    %% ── Edges ────────────────────────────────────────────────
    SRC_CUSTOMERS --> STG_CUST
    SRC_CUSTOMERS --> STG_CUST_HIST
    SRC_ORDERS    --> STG_ORD

    STG_CUST --> HUB_CUST
    STG_CUST --> SAT
    STG_ORD  --> HUB_ORD
    STG_ORD  --> LINK

    HUB_CUST --> DIM_CUST
    SAT      --> DIM_CUST

    STG_ORD  --> FACT_REV
    DIM_CUST --> FACT_REV

    FACT_REV --> FEAT_REV90
    FACT_REV --> SLA
    FACT_REV --> Q_RECON
    FACT_REV --> Q_ANOM

    SRC_ORDERS --> Q_RECON
    STG_ORD    --> Q_RECON

    %% ── Styles ───────────────────────────────────────────────
    classDef source   fill:#4a4a8a,color:#fff,stroke:#7070cc
    classDef staging  fill:#2d6a4f,color:#fff,stroke:#52b788
    classDef vault    fill:#7b3f00,color:#fff,stroke:#c77b2a
    classDef mart     fill:#1a4971,color:#fff,stroke:#3a86c8
    classDef feature  fill:#4a1a6a,color:#fff,stroke:#9b5dc8
    classDef obs      fill:#1a4a3a,color:#fff,stroke:#2da87a
    classDef quality  fill:#5a4a1a,color:#fff,stroke:#c8a830

    class SRC_CUSTOMERS,SRC_ORDERS source
    class STG_CUST,STG_CUST_HIST,STG_ORD staging
    class HUB_CUST,HUB_ORD,LINK,SAT vault
    class DIM_CUST,FACT_REV mart
    class FEAT_REV90 feature
    class SLA obs
    class Q_RECON,Q_ANOM quality
```

The platform separates ingestion, integration, serving and monitoring so each layer has a clear owner, SLA and rollback path.
