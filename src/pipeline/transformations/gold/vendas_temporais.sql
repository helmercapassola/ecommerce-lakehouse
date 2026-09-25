-- =============================================================
-- GOLD.VENDAS_TEMPORAIS
-- Análise temporal de vendas para a Diretoria Comercial.
--
-- OBJETIVO: Responder "quanto vendemos, quando (dia, hora,
-- dia da semana) e em qual canal". Uma linha por data x hora x
-- canal_venda, com totais de vendas, itens, receita e clientes
-- únicos.
--
-- PERÍODO: 13/12/2025 a 11/01/2026.
--
-- INCLUI TODAS AS VENDAS, inclusive de produto não cadastrado:
-- dinheiro que entrou é receita e não pode ser descartado.
--
-- AVISO: clientes_unicos usa COUNT DISTINCT por linha. Não somar
-- entre linhas (um cliente pode comprar em vários dias/horas/canais).
-- Para clientes únicos no período, use gold.clientes_segmentacao.
-- =============================================================

CREATE OR REFRESH MATERIALIZED VIEW gold.vendas_temporais (
    dados DATE COMMENT 'Data da venda (formato ISO: YYYY-MM-DD). Período dos dados: 13/12/2025 a 11/01/2026',
    dia_semana STRING COMMENT 'Nome do dia da semana em português (Domingo, Segunda, Terça, Quarta, Quinta, Sexta, Sábado)',
    dia_semana_num INT COMMENT 'Número do dia da semana: 1=Domingo, 2=Segunda, ..., 7=Sábado',
    hora INT COMMENT 'Hora da venda (0 a 23). Extraída do timestamp data_venda',
    canal_venda STRING COMMENT 'Canal de venda: ecommerce ou loja_fisica',
    total_vendas BIGINT COMMENT 'Total de vendas (transações) na combinação data x hora x canal',
    itens_vendidos BIGINT COMMENT 'Total de itens vendidos (soma de quantidade). Inclui TODAS as vendas, inclusive de produto não cadastrado',
    receita DECIMAL(10, 2) COMMENT 'Receita total em R$ (soma de receita). Inclui TODAS as vendas, inclusive de produto não cadastrado',
    clientes_unicos BIGINT COMMENT 'Número de clientes distintos na combinação data x hora x canal. NÃO somar entre linhas: um cliente pode comprar em vários dias/horas/canais. Para clientes únicos no período, use gold.clientes_segmentacao'
)
COMMENT 'Análise temporal de vendas por data x hora x canal_venda para a Diretoria Comercial. Use para responder quanto vendemos, quando e em qual canal. Período: 13/12/2025 a 11/01/2026.'
AS
SELECT
    CAST(data AS DATE) AS dados,
    CAST(dia_semana AS STRING) AS dia_semana,
    CAST(dia_semana_num AS INT) AS dia_semana_num,
    CAST(hora AS INT) AS hora,
    CAST(canal_venda AS STRING) AS canal_venda,
    CAST(COUNT(*) AS BIGINT) AS total_vendas,
    CAST(SUM(quantidade) AS BIGINT) AS itens_vendidos,
    CAST(SUM(receita) AS DECIMAL(10, 2)) AS receita,
    CAST(COUNT(DISTINCT id_cliente) AS BIGINT) AS clientes_unicos
FROM silver.vendas
GROUP BY ALL