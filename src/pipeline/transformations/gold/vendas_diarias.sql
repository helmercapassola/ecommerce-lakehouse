-- =============================================================
-- GOLD.VENDAS_DIARIAS
-- Agregação diária de vendas por canal de venda.
--
-- OBJETIVO: Alimentar dashboards de receita e volume ao longo
-- do tempo, separando ecommerce de loja física.
--
-- MÉTRICAS:
-- - total_vendas: número de transações no dia/canal
-- - total_itens: soma de unidades vendidas
-- - receita_total: soma de receita (DECIMAL(10,2))
-- - ticket_medio: receita_total / total_vendas
-- - receita_suspeita: soma de receita onde preco_suspeito = true
--   (permite monitorar impacto de outliers sem descartar linhas)
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_diarias (
    data DATE COMMENT 'Data da venda (formato ISO: YYYY-MM-DD)',
    canal_venda STRING COMMENT 'Canal de venda: ecommerce ou loja_fisica',
    total_vendas BIGINT COMMENT 'Total de vendas (transações) no dia/canal',
    total_itens BIGINT COMMENT 'Total de itens vendidos (soma de quantidade) no dia/canal',
    receita_total DECIMAL(10, 2) COMMENT 'Receita total em R$ no dia/canal (soma de receita)',
    ticket_medio DECIMAL(10, 2) COMMENT 'Ticket médio em R$ (receita_total / total_vendas)',
    receita_suspeita DECIMAL(10, 2) COMMENT 'Receita suspeita em R$ (soma de receita onde preco_suspeito = true). Permite monitorar impacto de outliers sem descartar linhas'
)
COMMENT 'Agregação diária de vendas por canal.'
CLUSTER BY (data, canal_venda)
AS
SELECT
    data,
    canal_venda,
    COUNT(*) AS total_vendas,
    SUM(quantidade) AS total_itens,
    CAST(SUM(receita) AS DECIMAL(10, 2)) AS receita_total,
    CAST(SUM(receita) / COUNT(*) AS DECIMAL(10, 2)) AS ticket_medio,
    CAST(SUM(CASE WHEN preco_suspeito THEN receita ELSE 0 END) AS DECIMAL(10, 2)) AS receita_suspeita
FROM silver.vendas
GROUP BY ALL;