# Architecture Diagram

## Visao Geral

O projeto segue a arquitetura Medallion do Databricks Lakehouse, com 4 camadas: Source -> Bronze -> Silver -> Gold -> Analytics.

## Diagrama

```mermaid
graph TD
    subgraph Sources["Data Sources"]
        S3["S3 Bucket: DataLakeEcommerce"]
        S3 --> F1[clientes.parquet]
        S3 --> F2[vendas.parquet]
        S3 --> F3[produtos.parquet]
        S3 --> F4[preco_competidores.parquet]
    end

    subgraph Ingestion["Ingestao"]
        NB["Notebook: ExtratLoad"]
        NB --> R1["boto3 + Pandas"]
        R1 --> R2["Spark DataFrame"]
    end

    subgraph Bronze["Camada Bronze - Delta Lake"]
        B1["ecommerce.bronze.clientes"]
        B2["ecommerce.bronze.vendas"]
        B3["ecommerce.bronze.produtos"]
        B4["ecommerce.bronze.preco_competidores"]
    end

    subgraph Silver["Camada Silver - PySpark SDP"]
        S1["silver.vendas"]
        S2["silver.produtos"]
        S3T["silver.clientes"]
        S4["silver.preco_competidores"]
    end

    subgraph Gold["Camada Gold - SQL SDP"]
        G1["gold.clientes_segmentacao"]
        G2["gold.vendas_detalhadas"]
        G3["gold.vendas_diarias"]
        G4["gold.vendas_por_produto"]
        G5["gold.vendas_por_cliente"]
        G6["gold.vendas_produtos"]
        G7["gold.vendas_temporais"]
        G8["gold.precos_competitividade"]
    end

    subgraph Analytics["Analytics"]
        D1["Dashboard: Vendas E-commerce"]
        D2["Dashboard: Comercial"]
        D3["Dashboard: Customer Success"]
        D4["Dashboard: Pricing"]
        GN["Genie Space"]
    end

    subgraph Quality["Qualidade"]
        T["16 Testes Automatizados"]
    end

    F1 --> NB
    F2 --> NB
    F3 --> NB
    F4 --> NB
    R2 --> B1
    R2 --> B2
    R2 --> B3
    R2 --> B4
    B1 --> S3T
    B2 --> S1
    B3 --> S2
    B4 --> S4
    S1 --> G1
    S1 --> G2
    S1 --> G3
    S1 --> G4
    S1 --> G5
    S1 --> G6
    S1 --> G7
    S2 --> G8
    S4 --> G8
    G1 --> D1
    G1 --> D3
    G1 --> G2
    G2 --> D2
    G3 --> D1
    G6 --> D2
    G7 --> D2
    G8 --> D4
    G1 --> GN
    G2 --> GN
    G8 --> GN
    S1 --> T
    G1 --> T
    G8 --> T
```

## Componentes

| Componente | Tecnologia | Descricao |
| --- | --- | --- |
| Source | S3 (Supabase) | 4 ficheiros Parquet no bucket DataLakeEcommerce |
| Ingestion | Python + boto3 + Pandas | Notebook le Parquet do S3, converte para Spark, escreve Delta |
| Bronze | Delta Lake | 4 tabelas no catalogo ecommerce.bronze |
| Silver | PySpark SDP | 4 materialized views com limpeza e enriquecimento |
| Gold | SQL SDP | 8 materialized views com agregacoes e metricas |
| Analytics | AI/BI Dashboards + Genie | 4 dashboards + Genie Space |
| Quality | Python | 16 testes automatizados pos-pipeline |
| Orquestracao | DAB | Job: pipeline + testes |
