# Data Lineage

## Source -> Bronze

| Ficheiro S3 | Tabela Bronze | Formato |
| --- | --- | --- |
| clientes.parquet | ecommerce.bronze.clientes | Delta Lake |
| vendas.parquet | ecommerce.bronze.vendas | Delta Lake |
| produtos.parquet | ecommerce.bronze.produtos | Delta Lake |
| preco_competidores.parquet | ecommerce.bronze.preco_competidores | Delta Lake |

## Bronze -> Silver

| Tabela Bronze | Tabela Silver | Transformacoes |
| --- | --- | --- |
| bronze.clientes | silver.clientes | Dedup (id_cliente), remove pronomes, initcap, UF->maiusculas, mapeamento IBGE |
| bronze.vendas | silver.vendas | Dedup (id_venda), DECIMAL(10,2), receita=qtyxpreco, outliers 3-sigma, join produtos, decomposicao temporal |
| bronze.produtos | silver.produtos | Dedup (id_produto), TRIM nome, DECIMAL(10,2), faixa_preco |
| bronze.preco_competidores | silver.preco_competidores | Dedup (id_produto+nome_concorrente), DECIMAL(10,2), preco_suspeito |

## Silver -> Gold

| Tabela(s) Silver | Tabela Gold | Tipo |
| --- | --- | --- |
| silver.clientes LEFT JOIN silver.vendas | gold.clientes_segmentacao | Segmentacao + ranking |
| silver.vendas LEFT JOIN silver.produtos LEFT JOIN silver.clientes LEFT JOIN gold.clientes_segmentacao | gold.vendas_detalhadas | Detalhada (1 linha por venda) |
| silver.vendas | gold.vendas_diarias | Agregacao diaria por canal |
| silver.produtos LEFT JOIN silver.vendas | gold.vendas_por_produto | Vendas por produto |
| silver.clientes LEFT JOIN silver.vendas | gold.vendas_por_cliente | Vendas por cliente |
| silver.vendas LEFT JOIN silver.produtos | gold.vendas_produtos | Produtos com rankings |
| silver.vendas | gold.vendas_temporais | Analise temporal |
| silver.produtos JOIN silver.preco_competidores LEFT JOIN silver.vendas | gold.precos_competitividade | Competitividade de precos |

## Gold -> Analytics

| Tabela Gold | Dashboard | Genie |
| --- | --- | --- |
| gold.clientes_segmentacao | Customer Success, Vendas Executiva | Sim |
| gold.vendas_detalhadas | Vendas Executiva, Comercial | Sim |
| gold.vendas_diarias | Vendas Executiva | Sim |
| gold.vendas_por_produto | Comercial | Sim |
| gold.vendas_por_cliente | Customer Success | Sim |
| gold.vendas_produtos | Comercial | Sim |
| gold.vendas_temporais | Comercial | Sim |
| gold.precos_competitividade | Pricing | Sim |
