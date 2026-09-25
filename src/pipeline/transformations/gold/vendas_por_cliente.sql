-- =============================================================
-- GOLD.VENDAS_POR_CLIENTE
-- Resumo de compras por cliente, com localização.
--
-- OBJETIVO: Segmentar clientes por receita, frequência e região,
-- alimentando análises de RFM e relatórios regionais.
--
-- MÉTRICAS:
-- - total_vendas: número de transações do cliente
-- - total_itens: soma de unidades compradas
-- - receita_total: soma de receita (DECIMAL(10,2))
-- - ticket_medio: receita_total / total_vendas
-- - primeira_compra: data da primeira venda
-- - ultima_compra: data da última venda
--
-- Nota: LEFT JOIN preserva clientes sem compras (receita = 0).
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_por_cliente (
    id_cliente STRING COMMENT 'Identificador único do cliente',
    nome_cliente STRING COMMENT 'Nome do cliente',
    estado STRING COMMENT 'Sigla do estado do cliente (ex: SP, MG, RJ)',
    regiao STRING COMMENT 'Região do cliente (ex: Sudeste, Sul, Nordeste)',
    total_vendas BIGINT COMMENT 'Total de vendas (transações) do cliente',
    total_itens BIGINT COMMENT 'Total de itens comprados (soma de quantidade)',
    receita_total DECIMAL(10, 2) COMMENT 'Receita total em R$ do cliente (soma de receita). 0 se nunca comprou',
    ticket_medio DECIMAL(10, 2) COMMENT 'Ticket médio em R$ (receita_total / total_vendas)',
    primeira_compra DATE COMMENT 'Data da primeira compra do cliente. NULL se nunca comprou',
    ultima_compra DATE COMMENT 'Data da última compra do cliente. NULL se nunca comprou'
)
COMMENT 'Resumo de compras por cliente, com localização.'
CLUSTER BY (regiao, estado)
AS
SELECT
    c.id_cliente,
    c.nome_cliente,
    c.estado,
    c.regiao,
    COUNT(v.id_venda) AS total_vendas,
    COALESCE(SUM(v.quantidade), 0) AS total_itens,
    CAST(COALESCE(SUM(v.receita), 0) AS DECIMAL(10, 2)) AS receita_total,
    CAST(COALESCE(SUM(v.receita), 0) / NULLIF(COUNT(v.id_venda), 0) AS DECIMAL(10, 2)) AS ticket_medio,
    MIN(v.data) AS primeira_compra,
    MAX(v.data) AS ultima_compra
FROM silver.clientes c
LEFT JOIN silver.vendas v ON c.id_cliente = v.id_cliente
GROUP BY ALL;