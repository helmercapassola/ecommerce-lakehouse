-- =============================================================
-- GOLD.VENDAS_POR_PRODUTO
-- Desempenho de vendas por produto, com categoria e marca.
--
-- OBJETIVO: Identificar produtos mais vendidos, receita por
-- categoria e marca, e ticket médio por produto.
--
-- MÉTRICAS:
-- - total_vendas: número de transações do produto
-- - total_itens: soma de unidades vendidas
-- - receita_total: soma de receita (DECIMAL(10,2))
-- - preco_medio: preço médio praticado (DECIMAL(10,2))
-- - ticket_medio: receita_total / total_vendas
--
-- Nota: LEFT JOIN preserva produtos sem vendas (receita = 0).
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_por_produto (
    id_produto STRING COMMENT 'Identificador único do produto',
    nome_produto STRING COMMENT 'Nome do produto',
    categoria STRING COMMENT 'Categoria do produto',
    marca STRING COMMENT 'Marca do produto',
    total_vendas BIGINT COMMENT 'Total de vendas (transações) do produto',
    total_itens BIGINT COMMENT 'Total de itens vendidos (soma de quantidade)',
    receita_total DECIMAL(10, 2) COMMENT 'Receita total em R$ do produto (soma de receita). 0 se nunca vendeu',
    preco_medio DECIMAL(10, 2) COMMENT 'Preço médio praticado em R$ (AVG de preco_unitario)',
    ticket_medio DECIMAL(10, 2) COMMENT 'Ticket médio em R$ (receita_total / total_vendas)'
)
COMMENT 'Desempenho de vendas por produto, com categoria e marca.'
CLUSTER BY (categoria, marca)
AS
SELECT
    p.id_produto,
    p.nome_produto,
    p.categoria,
    p.marca,
    COUNT(v.id_venda) AS total_vendas,
    COALESCE(SUM(v.quantidade), 0) AS total_itens,
    CAST(COALESCE(SUM(v.receita), 0) AS DECIMAL(10, 2)) AS receita_total,
    CAST(AVG(v.preco_unitario) AS DECIMAL(10, 2)) AS preco_medio,
    CAST(COALESCE(SUM(v.receita), 0) / NULLIF(COUNT(v.id_venda), 0) AS DECIMAL(10, 2)) AS ticket_medio
FROM silver.produtos p
LEFT JOIN silver.vendas v ON p.id_produto = v.id_produto
GROUP BY ALL;